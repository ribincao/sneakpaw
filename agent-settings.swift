import AppKit
import SwiftUI

final class AgentStatus: ObservableObject {
    @Published var available = false
    @Published var lastReply = UserDefaults.standard.object(forKey:"lastCodexReply") as? Date
    func confirm() {
        lastReply = Date()
        UserDefaults.standard.set(lastReply,forKey:"lastCodexReply")
    }
}

struct AgentSettings: View {
    @ObservedObject var status: AgentStatus
    let instructions: String
    let preview: () -> Void
    @State private var connecting = false
    @State private var copied = false
    var body: some View {
        HStack(alignment:.top,spacing:0) {
            VStack(alignment:.leading) {
                Label("Agent Notifications",systemImage:"bubble.left.and.text.bubble.right")
                    .padding(8).background(.quaternary,in:RoundedRectangle(cornerRadius:7))
                Spacer()
            }.padding(12).frame(width:179)
            Divider()
            VStack(alignment:.leading,spacing:16) {
                Text("Agent Notifications").font(.title2.bold())
                Text("Show a short reply above your cat when Codex finishes a turn.")
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName:"terminal").font(.title2)
                    VStack(alignment:.leading,spacing:3) {
                        Text("Codex").font(.headline)
                        Text(!status.available ? "Receiver unavailable" : status.lastReply == nil ? "Waiting for first reply" : "Connected")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(status.lastReply == nil ? "Connect…" : "Setup…") {
                        copied = false; connecting = true
                    }.disabled(!status.available)
                }.padding(12).background(.quaternary,in:RoundedRectangle(cornerRadius:10))
                if let date = status.lastReply {
                    Text("Last reply: " + date.formatted()).font(.caption).foregroundStyle(.secondary)
                }
                Button("Preview Bubble",action:preview)
                Spacer()
            }.padding(22).frame(width:355,alignment:.leading)
        }.frame(height:262)
        .sheet(isPresented:$connecting) {
            VStack(alignment:.leading,spacing:14) {
                Text("Send this to Codex").font(.title2.bold())
                ScrollView { Text(instructions).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading).padding(10) }
                    .frame(height:155).background(.quaternary,in:RoundedRectangle(cornerRadius:8))
                HStack {
                    Button("Done") { connecting = false }
                    Spacer()
                    Button(copied ? "Copied" : "Copy Instructions") {
                        NSPasteboard.general.clearContents()
                        copied = NSPasteboard.general.setString(instructions,forType:.string)
                    }.keyboardShortcut(.defaultAction)
                }
            }.padding(22).frame(width:438)
        }
    }
}

final class ReplyBubble {
    private let panel = PetPanel(contentRect:NSRect(x:0,y:0,width:235,height:80),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
    private weak var pet: NSPanel?
    private var timer: Timer?
    private var title = ""
    private var message = ""
    private var expanded = false
    private var remaining: TimeInterval = 6
    private var lastTick: TimeInterval = 0
    private var above = true
    init() {
        panel.backgroundColor = .clear; panel.isOpaque = false
        panel.ignoresMouseEvents = true; panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces,.fullScreenAuxiliary,.ignoresCycle]
        panel.level = .statusBar
    }
    func show(_ text:String, source:String = "Codex", context:String? = nil, on pet:NSPanel) {
        timer?.invalidate()
        self.pet = pet
        title = context.flatMap { $0.isEmpty ? nil : source + " · " + $0 } ?? source
        message = text.split(whereSeparator: { $0.isWhitespace }).joined(separator:" ")
        remaining = 6
        lastTick = ProcessInfo.processInfo.systemUptime
        expanded = false
        let screen = pet.screen?.visibleFrame ?? pet.frame
        above = screen.maxY-pet.frame.maxY >= 72 || screen.maxY-pet.frame.maxY >= pet.frame.minY-screen.minY
        layout()
        if panel.parent !== pet { pet.addChildWindow(panel,ordered:.above) }
        panel.orderFrontRegardless()
        // Keep clicks passing through to the user's app, including while reading.
        let clock = Timer(timeInterval:0.08,repeats:true) { [weak self] _ in
            self?.tick()
        }
        timer = clock
        RunLoop.main.add(clock,forMode:.common)
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let hovering = panel.frame.contains(NSEvent.mouseLocation)
        if !expanded && !hovering { remaining -= now-lastTick }
        lastTick = now
        if hovering != expanded {
            expanded = hovering
            layout()
        }
        if remaining <= 0 || pet == nil {
            timer?.invalidate()
            timer = nil
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
        }
    }

    private func layout() {
        guard let pet else { return }
        let screen = pet.screen?.visibleFrame ?? pet.frame
        let width = min(screen.width, expanded ? 330 : 235)
        let content = VStack(alignment:.leading,spacing:4) {
            Label(title,systemImage:"terminal")
                .lineLimit(1).truncationMode(.tail).font(.system(size:11,weight:.semibold)).foregroundStyle(.secondary)
            Text(verbatim:message).font(.system(size:13)).lineLimit(expanded ? nil : 2)
                .fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading)
        }.padding(.horizontal,13).padding(.vertical,10)
         .background(.regularMaterial,in:RoundedRectangle(cornerRadius:14))
         .overlay(RoundedRectangle(cornerRadius:14).stroke(.secondary.opacity(0.25)))
         .padding(3).frame(width:width)
        let hosting = NSHostingView(rootView:content)
        let height = min(screen.height,ceil(hosting.fittingSize.height))
        let x = max(screen.minX,min(pet.frame.midX-width/2,screen.maxX-width))
        let y = above ? pet.frame.maxY-3 : pet.frame.minY-height+3
        panel.contentView = hosting
        panel.setFrame(NSRect(x:x,y:max(screen.minY,min(y,screen.maxY-height)),width:width,height:height),display:true)
    }
}
