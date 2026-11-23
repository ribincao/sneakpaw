import AppKit
import Carbon
import SwiftUI

final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class Controller: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let pet = PetView(frame: CGRect(x: 0, y: 0, width: 201, height: 171))
    lazy var panel = PetPanel(contentRect: pet.bounds, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let keys = NSMenuItem(title: "Mimic Typing", action: #selector(toggleKeys), keyEquivalent: "")
    let receiver = AgentReceiver()
    let agentStatus = AgentStatus()
    let replyBubble = ReplyBubble()
    var settings: NSWindow?
    var permissionCheck: Timer?
    var tap: CFMachPort?
    var source: CFRunLoopSource?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.contentView = pet
        pet.bounds.size = CGSize(width: 268, height: 228)
        restorePosition()
        panel.orderFrontRegardless()
        NotificationCenter.default.addObserver(self, selector: #selector(restorePosition), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        status.button?.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Sneakpaw")
        let menu = NSMenu()
        let cats = NSMenu(title: "Cat")
        for style in CatStyle.allCases {
            let item = cats.addItem(withTitle: style.title, action: #selector(selectCat(_:)), keyEquivalent: "")
            item.representedObject = style.rawValue
            item.target = self
            item.state = style == pet.catStyle ? .on : .off
        }
        pet.showCatPicker = { [weak self] point in
            guard let self else { return }
            cats.popUp(positioning:nil, at:point, in:pet)
        }
        let keyboards = NSMenu(title: "Keyboard")
        for style in KeyboardStyle.allCases {
            let item = keyboards.addItem(withTitle: style.rawValue.capitalized, action: #selector(selectKeyboard(_:)), keyEquivalent: "")
            item.representedObject = style.rawValue
            item.target = self
            item.state = style == pet.keyboardStyle ? .on : .off
        }
        for submenu in [cats, keyboards] {
            menu.addItem(withTitle: submenu.title, action: nil, keyEquivalent: "").submenu = submenu
        }
        menu.addItem(.separator())
        keys.target = self
        menu.addItem(keys)
        let reset = menu.addItem(withTitle: "Move to Bottom Right of Current Display", action: #selector(resetPosition), keyEquivalent: "")
        reset.target = self
        menu.addItem(.separator())
        let preferences = menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        preferences.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        preferences.target = self
        receiver.availability = { [weak self] ready in self?.agentStatus.available = ready }
        receiver.received = { [weak self] event in
            guard let self else { return }
            if event.source == "codex" && event.type == "turn.completed" { agentStatus.confirm() }
            replyBubble.show(event.preview.isEmpty ? "Reply ready" : event.preview, source:event.source == "codex" ? "Codex" : event.source, context:event.chat_name, on:panel)
        }
        receiver.start()
        if CommandLine.arguments.contains("--agent-settings") { showSettings() }
        menu.addItem(withTitle: "Quit Sneakpaw", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        status.menu = menu
        if CommandLine.arguments.contains("--enable-mimic-typing") {
            enableKeys(requestAccess: true)
        } else if UserDefaults.standard.bool(forKey: "watchKeys") {
            enableKeys(requestAccess: false)
        }
    }

    @objc func showSettings() {
        if settings == nil {
            let installer = Bundle.main.url(forResource:"install-codex",withExtension:"py")!.path
            func quoted(_ path:String) -> String { "'" + path.replacingOccurrences(of:"'",with:"'\\''") + "'" }
            let instructions = """
            Connect Sneakpaw to my local Codex Stop hook. Run this bundled installer:

            python3 \(quoted(installer)) \(quoted(receiver.pairingURL.path))

            Preserve my notify setting and existing hooks. Show me how to review and trust the new hook. Then verify the first bubble with a real Codex reply.
            """
            let view = AgentSettings(status:agentStatus,instructions:instructions) { [weak self] in
                guard let self else { return }; replyBubble.show("This is how a Codex reply will appear.",context:"Sneakpaw",on:panel)
            }
            let window = NSWindow(contentViewController:NSHostingController(rootView:view))
            window.title = "Sneakpaw Settings"
            window.styleMask = [.titled,.closable]
            window.isReleasedWhenClosed = false
            window.center(); settings = window
        }
        NSApp.activate(ignoringOtherApps:true)
        settings?.makeKeyAndOrderFront(nil)
    }

    @objc func selectCat(_ item: NSMenuItem) {
        guard let id = item.representedObject as? String, let style = CatStyle(rawValue: id) else { return }
        pet.catStyle = style
        markSelected(item)
    }

    @objc func selectKeyboard(_ item: NSMenuItem) {
        guard let id = item.representedObject as? String, let style = KeyboardStyle(rawValue: id) else { return }
        pet.keyboardStyle = style
        markSelected(item)
    }

    private func markSelected(_ item: NSMenuItem) {
        for option in item.menu?.items ?? [] { option.state = option === item ? .on : .off }
    }

    @objc func resetPosition() {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main else { return }
        panel.setFrameOrigin(CGPoint(x: screen.visibleFrame.maxX - panel.frame.width - 20, y: screen.visibleFrame.minY + 18))
        pet.savePosition()
    }

    @objc func restorePosition() {
        if let saved = UserDefaults.standard.string(forKey: "origin") {
            let origin = NSPointFromString(saved)
            let bodyInWindow = pet.convert(CGRect(x: 90, y: 68, width: 72, height: 90), to: nil)
            let body = bodyInWindow.offsetBy(dx: origin.x, dy: origin.y)
            if NSScreen.screens.contains(where: { $0.visibleFrame.contains(body) }) {
                panel.setFrameOrigin(origin)
                return
            }
        }
        resetPosition()
    }

    @objc func toggleKeys() {
        if tap != nil || permissionCheck != nil {
            UserDefaults.standard.set(false, forKey: "watchKeys")
            permissionCheck?.invalidate()
            permissionCheck = nil
            if let tap { CFMachPortInvalidate(tap) }
            if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
            tap = nil
            source = nil
            keys.state = .off
            keys.title = "Mimic Typing"
            pet.clearKeys()
        } else {
            enableKeys(requestAccess: true)
        }
    }

    private func enableKeys(requestAccess: Bool) {
        // System Settings may quit us while applying the grant.
        UserDefaults.standard.set(true, forKey: "watchKeys")
        UserDefaults.standard.synchronize()
        if CGPreflightListenEventAccess() {
            startKeys()
        } else if requestAccess && CGRequestListenEventAccess() {
            startKeys()
        }
        if tap != nil { return }
        keys.title = "Mimic Typing (Waiting for Access)"
        keys.state = .mixed
        permissionCheck = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if CGPreflightListenEventAccess() { self.startKeys() }
            if self.tap != nil {
                timer.invalidate()
                self.permissionCheck = nil
            }
        }
        if requestAccess {
            let alert = NSAlert()
            alert.messageText = "Allow This Copy of Sneakpaw"
            alert.informativeText = "In Input Monitoring, use + to add this running copy. If an older Sneakpaw entry is already enabled, remove it first. Reopen Sneakpaw if macOS requests it."
            alert.addButton(withTitle: "Show App and Open Settings")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    func startKeys() {
        let callback: CGEventTapCallBack = { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let app = Unmanaged<Controller>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout, let tap = app.tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            } else if type == .keyDown, !IsSecureEventInputEnabled(), let key = NSEvent(cgEvent: event) {
                app.pet.strike(key)
            }
            return Unmanaged.passUnretained(event)
        }
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap, options: .listenOnly, eventsOfInterest: 1 << CGEventType.keyDown.rawValue, callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            keys.toolTip = "Check Input Monitoring in System Settings, then reopen Sneakpaw."
            return
        }
        tap = port
        source = CFMachPortCreateRunLoopSource(nil, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        keys.title = "Mimic Typing"
        keys.toolTip = nil
        keys.state = .on
    }
}

let app = NSApplication.shared
let controller = Controller()
app.setActivationPolicy(.accessory)
app.delegate = controller
app.run()
