"""Install one per-user Stop hook without changing config.toml or trust decisions."""
import json
import os
import shlex
import shutil
import sys
import tempfile
import fcntl
from pathlib import Path

def install(pair):
    if not pair.is_file():
        raise SystemExit("Open Sneakpaw and wait for its receiver to start.")
    home = Path(os.environ.get("CODEX_HOME", "~/.codex")).expanduser()
    folder = home / "sneakpaw"
    folder.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (folder / "install.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        script = folder / "codex-stop.pl"
        source = Path(__file__).with_name("codex-stop.pl").read_bytes()
        def replace(path, data):
            with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as out:
                out.write(data)
            os.replace(out.name, path)
        replace(script, source)
        path = home / "hooks.json"
        original = path.read_bytes() if path.exists() else None
        doc = json.loads(original) if original else {}
        stops = doc.setdefault("hooks", {}).setdefault("Stop", [])
        prefix = shlex.join(["/usr/bin/perl", str(script)]) + " "
        cmd = prefix + shlex.quote(str(pair))
        entry = {"type":"command", "command":cmd, "timeout":3}
        installed = [h for group in stops for h in group.get("hooks", []) if h.get("command", "").startswith(prefix)]
        if installed:
            installed[0].update(entry)
        else:
            stops.append({"hooks":[entry]})
        if original is None or doc != json.loads(original):
            if original and not (folder / "hooks.before-sneakpaw.json").exists():
                shutil.copyfile(path, folder / "hooks.before-sneakpaw.json")
            replace(path, (json.dumps(doc, ensure_ascii=False, indent=2)+"\n").encode())
    print("Installed. Review and trust the Sneakpaw Stop hook in Codex, then send one message.")

if __name__ == "__main__":
    install(Path(sys.argv[1]))
