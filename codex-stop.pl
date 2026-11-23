use strict;
use warnings;
use JSON::PP;
use IO::Socket::INET;
use File::Basename qw(basename dirname);

# Codex appends renames to its per-user session index. Use the last match,
# never a different chat's title or the text of the first user prompt.
sub chat_name {
    my ($input) = @_;
    my $home = $ENV{CODEX_HOME} || "$ENV{HOME}/.codex";
    my $name = '';
    if (open my $index, '<:raw', "$home/session_index.jsonl") {
        local $/ = "\n";
        while (my $line = <$index>) {
            next if index($line, $input->{session_id}) < 0;
            my $entry = eval { decode_json($line) };
            next unless ref($entry) eq 'HASH' && ($entry->{id} // '') eq $input->{session_id};
            $name = $entry->{thread_name} // '';
        }
    }
    $name =~ s/\s+/ /g;
    $name =~ s/^ +| +$//g;
    return substr($name, 0, 120) if length($name);
    my $cwd = $input->{cwd} // '';
    return '' unless $cwd =~ m{^/};
    my $project = $cwd;
    for (my $dir = $cwd; $dir ne '/'; $dir = dirname($dir)) {
        if (-e "$dir/.git") { $project = $dir; last }
    }
    return $project eq '/' ? '' : substr(basename($project), 0, 120);
}

# Always let Codex finish its turn, including when Sneakpaw is closed.
$SIG{ALRM} = sub { print "{}\n"; exit 0 };
$SIG{PIPE} = 'IGNORE';
alarm 2;
eval {
    local $/;
    my $input = decode_json(<STDIN>);
    die unless ($input->{hook_event_name} // '') eq 'Stop';
    my ($session, $turn) = @{$input}{qw(session_id turn_id)};
    die unless defined $session && defined $turn && length($session) && length($turn);
    open my $file, '<', $ARGV[0] or die;
    my $pair = decode_json(<$file>);
    close $file;
    my $text = $input->{last_assistant_message} // '';
    $text =~ s/^\s+|\s+$//g;
    $text =~ s/\s+/ /g;
    $text = 'Reply ready' unless length $text;
    my $body = encode_json({ version => 1, source => 'codex', type => 'turn.completed',
        chat_name => chat_name($input), event_id => "codex:$session:$turn", preview => substr($text,0,180) });
    my $socket = IO::Socket::INET->new(PeerAddr=>'127.0.0.1',PeerPort=>$pair->{port},Proto=>'tcp',Timeout=>1) or die;
    print $socket "POST /v1/events HTTP/1.1\r\nHost: 127.0.0.1\r\nAuthorization: Bearer $pair->{token}\r\nContent-Type: application/json\r\nContent-Length: ".length($body)."\r\nConnection: close\r\n\r\n".$body;
    close $socket;
};
alarm 0;
print "{}\n";
