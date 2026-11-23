import AppKit
import QuartzCore

private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
private func mix(_ a: CGPoint, _ b: CGPoint, _ f: CGFloat) -> CGPoint {
    pt(a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f)
}
private func shade(_ rgb: Int) -> NSColor {
    NSColor(srgbRed: CGFloat(rgb >> 16) / 255, green: CGFloat(rgb >> 8 & 255) / 255, blue: CGFloat(rgb & 255) / 255, alpha: 1)
}
enum CatStyle: String, CaseIterable {
    case ragdoll
    case bombay = "midnight" // Keep the existing black-cat preference.
    case golden, silver, orange, seal, lihua, exotic
    case devonRex, maineCoon, siamese, americanShorthair, sphynx
    var title: String {
        switch self {
        case .ragdoll: return "Ragdoll（布偶貓）"
        case .bombay: return "Bombay（孟買貓）"
        case .golden: return "Golden Shaded（金漸層）"
        case .silver: return "Silver Shaded（銀漸層）"
        case .orange: return "Orange Tabby（橘貓）"
        case .seal: return "Seal Bicolor Ragdoll（海豹雙色布偶貓）"
        case .lihua: return "Chinese Li Hua（狸花貓）"
        case .exotic: return "Exotic Shorthair（加菲貓）"
        case .devonRex: return "Devon Rex（德文卷毛貓）"
        case .maineCoon: return "Maine Coon（緬因貓）"
        case .siamese: return "Siamese（暹羅貓）"
        case .americanShorthair: return "American Shorthair（美國短毛貓）"
        case .sphynx: return "Sphynx（斯芬克斯貓）"
        }
    }
}
enum KeyboardStyle: String, CaseIterable {
    case buttermilk, graphite
    case sakura = "sakura milk"
    case matcha = "matcha ceramic"
    case glacier = "glacier glass"
    case retro = "retro terminal"
    case walnut = "walnut studio"
}
private struct CatSkin {
    let image: NSImage
    let rect: CGRect
    let eyes, shoulders: [CGPoint]
    let foreleg: NSImage
    static let ragdoll = CatSkin(image: Bundle.main.image(forResource: "ragdoll")!,
        rect: CGRect(x: 48, y: 6, width: 179, height: 186),
        eyes: [pt(113,55), pt(143.3,54.3)], shoulders: [pt(102,112),pt(152,112)],
        foreleg: Bundle.main.image(forResource: "ragdoll-leg")!)
    static let bombay = CatSkin(image: Bundle.main.image(forResource: "bombay")!,
        rect: CGRect(x: 48, y: 6, width: 179, height: 186),
        eyes: [pt(114,55.5), pt(146,55.5)], shoulders: [pt(103,109),pt(151,109)], foreleg: Bundle.main.image(forResource: "bombay-leg")!)
    private static let coatEyes: [CatStyle:[CGPoint]] = [
        .devonRex: [pt(121,51), pt(153,51)],
        .maineCoon: [pt(114,61), pt(140,61)],
        .siamese: [pt(113,58), pt(144,57)],
        .americanShorthair: [pt(108,59), pt(142,59)],
        .sphynx: [pt(117,60), pt(149,60)],
        .golden: [pt(110.5,55), pt(141.5,55)],
        .silver: [pt(111,54), pt(142.5,54)],
        .orange: [pt(112,58), pt(143.5,58)],
        .seal: [pt(111.5,55), pt(142.5,54)],
        .lihua: [pt(113.5,58), pt(145.5,58)],
        .exotic: [pt(114,55), pt(149.5,54)]
    ]
    static let collection: [CatStyle:CatSkin] = {
        var result: [CatStyle:CatSkin] = [.ragdoll:.ragdoll, .bombay:.bombay]
        for style in CatStyle.allCases where result[style] == nil {
            let name = style.rawValue
            func image(_ variant: String) -> NSImage {
                NSImage(contentsOf: Bundle.main.url(forResource: name + variant, withExtension: "png", subdirectory: "Coats")!)!
            }
            let marks = coatEyes[style]!
            result[style] = CatSkin(image: image(""), rect: ragdoll.rect, eyes: marks,
                shoulders: [pt((marks[0].x + marks[1].x)/2-24,111),pt((marks[0].x + marks[1].x)/2+24,111)],
                foreleg: image("-leg"))
        }
        return result
    }()
    static let lifts: [CatStyle:NSImage] = {
        var images = [CatStyle.ragdoll:Bundle.main.image(forResource: "ragdoll-lift")!]
        for style in CatStyle.allCases where style != .ragdoll {
            let url = Bundle.main.url(forResource: style.rawValue + "-lift", withExtension: "png", subdirectory: "Coats")!
            images[style] = NSImage(contentsOf: url)!
        }
        return images
    }()

}

private struct KeyboardSkin {
    let base, cap, edge, accent, legend: NSColor
    static let graphite = KeyboardSkin(base: shade(0x282c34), cap: shade(0x434955), edge: shade(0x1c2027),
        accent: shade(0x5e728e), legend: shade(0xf5f4ec))
    static let buttermilk = KeyboardSkin(base: shade(0x343332), cap: shade(0xfff4dc), edge: shade(0xc7b89e),
        accent: shade(0xffbd51), legend: shade(0x685f52))
    static let finishes: [KeyboardStyle:KeyboardSkin] = {
        func finish(_ base: Int, _ cap: Int, _ edge: Int, _ accent: Int, _ legend: Int) -> KeyboardSkin {
            KeyboardSkin(base: shade(base), cap: shade(cap), edge: shade(edge), accent: shade(accent), legend: shade(legend))
        }
        return [.buttermilk:.buttermilk, .graphite:.graphite,
                .sakura:finish(0xB56C86,0xFFE8E9,0xC892A4,0xF49EAD,0x6C3449),
                .matcha:finish(0x566B4A,0xE6ECD3,0xA6B494,0xADC781,0x384633),
                .glacier:finish(0x69B5D2,0xD9F7FF,0x8DC9DD,0xA9C3FA,0x24516B),
                .retro:finish(0x202B27,0x35473B,0x15241D,0x48724A,0xB7F9A3),
                .walnut:finish(0x795138,0xF1D9AD,0xAB835D,0xD19558,0x543827)]
    }()

}

private struct KeyCap {
    let code: UInt16
    let legend: String
    let rect: CGRect
    var center: CGPoint { pt(rect.midX, rect.midY) }
    static let board: [KeyCap] = {
        let rows: [([UInt16], [String])] = [
            ([18,19,20,21,23,22,26,28,25,29,27,24], Array("1234567890-=").map(String.init)),
            ([12,13,14,15,17,16,32,34,31,35,33,30], Array("QWERTYUIOP[]").map(String.init)),
            ([0,1,2,3,5,4,38,40,37,41,39,36], Array("ASDFGHJKL;'↵").map(String.init)),
            ([6,7,8,9,11,45,46,43,47,44], Array("ZXCVBNM,./").map(String.init))]
        var caps: [KeyCap] = []
        for (r,row) in rows.enumerated() {
            for (i,code) in row.0.enumerated() {
                caps.append(KeyCap(code: code, legend: row.1[i], rect: CGRect(x: 55 + Double(i)*15.2 + Double(r)*2, y: 170 + 9*Double(r), width: 13.8, height: 7.9)))
            }
        }
        caps.append(KeyCap(code: 49, legend: "", rect: CGRect(x: 102,y: 206,width: 95,height: 7)))
        // Rotate the physical layout around the deck center. The cat faces the viewer.
        return caps.map { key in
            let r = key.rect
            return KeyCap(code: key.code, legend: key.legend,
                          rect: CGRect(x: 297-r.maxX, y: 384-r.maxY, width: r.width, height: r.height))
        }
    }()
}
private struct Stroke {
    let point: CGPoint
    let label: String
    let time: TimeInterval
    let code: UInt16
}
final class PetView: NSView {
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    var catStyle = CatStyle(rawValue: UserDefaults.standard.string(forKey: "catStyle") ?? "") ?? .ragdoll {
        didSet { UserDefaults.standard.set(catStyle.rawValue, forKey: "catStyle"); needsDisplay = true }
    }
    var keyboardStyle = KeyboardStyle(rawValue: UserDefaults.standard.string(forKey: "keyboardStyle") ?? "") ?? .buttermilk {
        didSet { UserDefaults.standard.set(keyboardStyle.rawValue, forKey: "keyboardStyle"); needsDisplay = true }
    }
    private var cat: CatSkin { CatSkin.collection[catStyle]! }
    private var keyboard: KeyboardSkin { KeyboardSkin.finishes[keyboardStyle]! }
    private var link: CADisplayLink?
    var showCatPicker: ((CGPoint) -> Void)?
    private var pendingPicker: DispatchWorkItem?
    private var dragAnchor: CGPoint?
    private var dragStart = CGPoint.zero
    private var dragging = false
    private var knockStarted: TimeInterval?
    private let catHitArea = NSBezierPath(ovalIn:CGRect(x:84,y:29,width:84,height:157))

    private var liftBlend: CGFloat = 0
    private var sway: CGFloat = 0
    private var swingVelocity: CGFloat = 0
    private var previousDragX: CGFloat = 0
    private var lastCursor: CGPoint?
    private var gaze = CGPoint.zero
    // The hip stays planted while chest and head settle at different speeds.
    private var chest = CGPoint.zero
    private var head = CGPoint.zero
    private let deckScale: CGFloat = 0.65
    private func deckPoint(_ p: CGPoint) -> CGPoint {
        pt(80 + (p.x-50)*deckScale, 159 + (p.y-166)*deckScale)
    }
    private var deckRect: CGRect {
        CGRect(origin: deckPoint(pt(50,166)), size: CGSize(width: 197*deckScale, height: 52*deckScale))
    }
    private var mouse = pt(63,173)
    private var mouseGoal = pt(63,173)
    private var keyboardGaze = false
    private var typingCursor = CGPoint.zero
    private var paws = [pt(63,170),pt(161.25,163.55)]
    private var targets = [pt(95,189),pt(191,184)]
    private var taps = [-100.0,-100.0]
    private var strokes: [Stroke] = []
    private var typing = false
    private var resting = false
    private var lastActivity = CACurrentMediaTime()
    private var previous = CACurrentMediaTime()
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        pendingPicker?.cancel()
        pendingPicker = nil
        link?.invalidate()
        if window != nil {
            link = displayLink(target: self, selector: #selector(step))
            link?.add(to: .main, forMode: .common)
        }
    }
    func savePosition() {
        if let window { UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: "origin") }
    }
    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        let p = window.convertPoint(toScreen: event.locationInWindow)
        pendingPicker?.cancel()
        pendingPicker = nil
        dragStart = p
        previousDragX = p.x
        dragAnchor = pt(p.x - window.frame.minX,p.y - window.frame.minY)
    }
    override func mouseDragged(with event: NSEvent) {
        guard let a = dragAnchor, let window else { return }
        let p = window.convertPoint(toScreen: event.locationInWindow)
        guard dragging || hypot(p.x-dragStart.x,p.y-dragStart.y) >= 3 else { return }
        knockStarted = nil
        dragging = true
        // Horizontal travel imparts momentum around the grip, including on reversal.
        swingVelocity = min(250, max(-250, swingVelocity + (p.x-previousDragX)*2.3))
        lastActivity = CACurrentMediaTime()
        setResting(false)
        previousDragX = p.x
        window.setFrameOrigin(pt(p.x-a.x,p.y-a.y))
    }
    override func mouseUp(with event: NSEvent) {
        if dragging {
            mouseDragged(with: event)
            savePosition()
        } else if dragAnchor != nil,
                  catHitArea.contains(convert(event.locationInWindow,from:nil)),
                  let window {
            let end = window.convertPoint(toScreen:event.locationInWindow)
            if hypot(end.x-dragStart.x,end.y-dragStart.y) < 3 {
                switch event.clickCount {
                case 1:
                    let point = convert(event.locationInWindow,from:nil)
                    let work = DispatchWorkItem { [weak self] in
                        self?.pendingPicker = nil
                        self?.showCatPicker?(point)
                    }
                    pendingPicker = work
                    DispatchQueue.main.asyncAfter(deadline:.now()+NSEvent.doubleClickInterval,execute:work)
                case 2:
                    lastActivity = CACurrentMediaTime()
                    knockStarted = lastActivity
                    setResting(false)
                    needsDisplay = true
                default:
                    break
                }
            }
        }
        dragging = false
        dragAnchor = nil
    }

    func clearKeys() { strokes.removeAll(); typing = false; keyboardGaze = false; needsDisplay = true }
    func strike(_ key: NSEvent) {
        let now = CACurrentMediaTime()
        let cap = KeyCap.board.first { $0.code == key.keyCode }
        let p = cap?.center ?? pt(230,188)
        let side = p.x < 147 ? 0 : 1
        targets[side] = p
        taps[side] = now
        typing = true
        keyboardGaze = true
        typingCursor = NSEvent.mouseLocation
        lastActivity = now
        setResting(false)
        guard !key.isARepeat else { return }
        let special: [UInt16:String] = [36:"↵",48:"⇥",49:"␣",51:"⌫",53:"esc",123:"←",124:"→",125:"↓",126:"↑"]
        let label = special[key.keyCode] ?? key.charactersIgnoringModifiers?.first.map(String.init) ?? "•"
        strokes.append(Stroke(point:p,label:label,time:now,code:key.keyCode))
        if strokes.count > 4 { strokes.removeFirst() }
    }

    private func setResting(_ value: Bool) {
        guard value != resting else { return }
        resting = value
        link?.preferredFrameRateRange = value ? CAFrameRateRange(minimum: 15, maximum: 30, preferred: 24) : .default
    }

    @objc func step() {
        guard let window else { return }
        let now = CACurrentMediaTime()
        let dt = min(0.08, now - previous)
        previous = now
        let cursor = NSEvent.mouseLocation
        let local = convert(window.convertPoint(fromScreen: cursor), from: nil)
        let interactive = catHitArea.contains(local)
            || deckRect.contains(local)
        window.ignoresMouseEvents = dragAnchor == nil && !interactive
        if let start = knockStarted {
            needsDisplay = true
            if now-start >= 0.55 { knockStarted = nil }
        }
        let oldLift = liftBlend
        liftBlend = dragging ? min(1,liftBlend+dt/0.13) : max(0,liftBlend-dt/0.16)
        let oldSway = sway
        if liftBlend > 0 {
            // Exact damped spring update, independent of display refresh rate.
            let amplitude = (swingVelocity + 4*sway)/9
            let decay: CGFloat = exp(-4*CGFloat(dt))
            let phase: CGFloat = 9*CGFloat(dt)
            let angle = decay*(sway*cos(phase) + amplitude*sin(phase))
            swingVelocity = decay*9*(amplitude*cos(phase) - sway*sin(phase)) - 4*angle
            sway = min(20, max(-20, angle))
            if sway != angle && sway*swingVelocity > 0 { swingVelocity = 0 }
        } else {
            sway = 0
            swingVelocity = 0
        }
        if liftBlend != oldLift || (liftBlend > 0 && abs(sway-oldSway)>0.005) {
            needsDisplay = true
        }
        if dragAnchor != nil { lastCursor = cursor; return }
        typing = now - (taps.max() ?? 0) < 0.32 && hypot(cursor.x-typingCursor.x,cursor.y-typingCursor.y) < 7
        if !typing || cursor != typingCursor { keyboardGaze = false }
        let lookAt = keyboardGaze ? pt(deckRect.midX,deckRect.midY) : local
        let eyeCenter = mix(cat.eyes[0], cat.eyes[1], 0.5)
        let dx = lookAt.x - eyeCenter.x, dy = lookAt.y - eyeCenter.y
        let d = max(70,hypot(dx,dy))
        let newGaze = mix(gaze,pt(4.3*dx/d,(keyboardGaze ? 4.8 : 3.0)*dy/d),1-exp(-dt*29))
        let oldMouse = mouse
        let oldPaws = paws
        let oldGaze = gaze
        gaze = newGaze
        if let lastCursor, cursor != lastCursor {
            mouseGoal = pt(min(68,max(49,mouseGoal.x+(cursor.x-lastCursor.x)*0.13)),
                           min(182,max(160,mouseGoal.y+(lastCursor.y-cursor.y)*0.13)))
            lastActivity = now
            setResting(false)
        }
        lastCursor = cursor
        mouse = mix(mouse,mouseGoal,1-exp(-dt*16))
        let oldChest = chest, oldHead = head
        let targetChest = typing ? pt(0,3) : .zero
        chest = mix(chest,targetChest,1-exp(-dt*15))
        head = mix(head,pt(chest.x*0.64,chest.y*0.62),1-exp(-dt*9))
        for side in 0...1 {
            let age = now-taps[side]
            // Lift to travel, settle onto the key, then release.
            let lift = age < 0.055 ? 8 * (1 - age / 0.055) : 6 * (1-exp(-max(0, age-0.085)*24))
            let key = deckPoint(targets[side])
            let parked = deckPoint(side == 0 ? pt(103,170) : pt(175,173))
            let rest = side == 0 && !typing ? pt(mouse.x,mouse.y-4) : parked
            let goal = typing && age < 0.28 ? pt(key.x,key.y-lift) : rest
            paws[side] = mix(paws[side],goal,1-exp(-dt*(typing ? 47 : 15)))
        }
        let had = !strokes.isEmpty
        strokes.removeAll { now-$0.time > 0.55 }
        let moved = zip([oldMouse,oldGaze]+oldPaws,[mouse,gaze]+paws).contains { hypot($0.x-$1.x,$0.y-$1.y)>0.008 }
        let bodyMoved = (hypot(chest.x-oldChest.x,chest.y-oldChest.y) +
            hypot(head.x-oldHead.x,head.y-oldHead.y) > 0.001)
        if moved || had || bodyMoved { needsDisplay = true }
        if now-lastActivity > 0.8 { setResting(true) }
    }

    private func box(_ rect: CGRect,_ r: CGFloat,_ color: NSColor) {
        color.setFill(); NSBezierPath(roundedRect:rect,xRadius:r,yRadius:r).fill()
    }
    private func label(_ s: String,_ p: CGPoint,_ size: CGFloat,_ color: NSColor) {
        let attrs: [NSAttributedString.Key:Any] = [.font:NSFont.monospacedSystemFont(ofSize:size,weight:.semibold),.foregroundColor:color]
        let str = s as NSString, m = str.size(withAttributes:attrs)
        str.draw(at:pt(p.x-m.width/2,p.y-m.height/2),withAttributes:attrs)
    }
    private func drawForeleg(side: Int, pressure: CGFloat, hop: CGFloat) {
        let image = cat.foreleg
        var shoulder = cat.shoulders[side]
        shoulder.x += chest.x
        shoulder.y += chest.y
        let contact = pt(paws[side].x,paws[side].y-hop)
        let direction: CGFloat = side == 0 ? -1 : 1
        let gripping = side == 0 && !typing
        let toe = pt(contact.x, contact.y + (gripping ? 5 : 2))
        let wrist = pt(toe.x-direction*(gripping ? 5 : 2), toe.y-(gripping ? 14 : 17)+3*pressure)
        let elbow = pt(shoulder.x+(wrist.x-shoulder.x)*0.46+direction*4,
                       shoulder.y+(wrist.y-shoulder.y)*0.51)
        // Join the painted upper leg, wrist and toes at shared horizontal edges.
        // A near-vertical paw stays cupped even when the forearm reaches sideways.
        let joints = [shoulder, elbow, wrist, toe]
        let cuts: [CGFloat] = [0, 0.46, 0.82, 1]
        let width: CGFloat = 28 + min(6, abs(wrist.x-shoulder.x)*0.08)
        for i in 0..<3 {
            let a = joints[i], b = joints[i+1]
            let height = b.y-a.y
            guard height > 0 else { continue }
            NSGraphicsContext.saveGraphicsState()
            let transform = NSAffineTransform()
            transform.transformStruct = NSAffineTransformStruct(
                m11: side == 0 ? 1 : -1, m12: 0, m21: (b.x-a.x)/height, m22: 1, tX: a.x, tY: a.y)
            transform.concat()
            let source = CGRect(x: 0, y: image.size.height*(1-cuts[i+1]), width: image.size.width,
                                height: image.size.height*(cuts[i+1]-cuts[i]))
            image.draw(in: CGRect(x: -width/2, y: 0, width: width, height: height+0.4),
                       from: source, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private func drawBody() {
        let rect = cat.rect
        // Continuous bands share edges. Move the head rigidly, bend the ruff
        // into the shoulders, and leave the bottom of the seated silhouette fixed.
        let bands: [(CGFloat,CGPoint)] = [(0,head),(0.39,head),(0.59,chest),(0.88,.zero),(1,.zero)]
        let size = cat.image.size
        for (top,bottom) in zip(bands,bands.dropFirst()) {
            let start = rect.minY+rect.height*top.0+top.1.y
            let height = rect.height*(bottom.0-top.0)+bottom.1.y-top.1.y
            let transform = NSAffineTransform()
            transform.transformStruct = NSAffineTransformStruct(m11:1,m12:0,m21:(bottom.1.x-top.1.x)/height,
                m22:1,tX:rect.minX+top.1.x,tY:start)
            NSGraphicsContext.saveGraphicsState()
            transform.concat()
            cat.image.draw(in:CGRect(x:0,y:0,width:rect.width,height:height+0.35),
                from:CGRect(x:0,y:size.height*(1-bottom.0),width:size.width,height:size.height*(bottom.0-top.0)),
                operation:.sourceOver,fraction:1,respectFlipped:true,hints:nil)
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    // Landmarks in each pickup illustration, measured on a 460 × 460 canvas.
    private struct Grip {
        let top, outer, bottom: CGPoint
        let paw: [CGPoint]
    }
    private static let grips: [CatStyle:Grip] = [
        .devonRex: Grip(top: pt(278,157), outer: pt(315,165), bottom: pt(232,308), paw: [pt(300,207), pt(289,216), pt(281,221), pt(273,232), pt(270,243), pt(273,251), pt(281,256), pt(290,255)]),
        .maineCoon: Grip(top: pt(269,155), outer: pt(308,165), bottom: pt(215,307), paw: [pt(288,207), pt(278,217), pt(267,221), pt(258,230), pt(255,243), pt(260,254), pt(268,259), pt(279,257)]),
        .siamese: Grip(top: pt(265,156), outer: pt(304,164), bottom: pt(213,308), paw: [pt(289,207), pt(276,218), pt(268,221), pt(260,231), pt(254,243), pt(260,253), pt(270,257), pt(278,255)]),
        .americanShorthair: Grip(top: pt(274,155), outer: pt(315,165), bottom: pt(221,304), paw: [pt(295,208), pt(285,217), pt(275,221), pt(267,231), pt(263,243), pt(270,253), pt(278,257), pt(287,255)]),
        .sphynx: Grip(top: pt(263,157), outer: pt(301,165), bottom: pt(209,305), paw: [pt(280,208), pt(272,218), pt(262,221), pt(254,231), pt(250,244), pt(255,253), pt(264,257), pt(273,255)]),
        .ragdoll: Grip(top: pt(294,151), outer: pt(329,161), bottom: pt(242,300), paw: [pt(312,210), pt(307,212), pt(299,216), pt(291,222), pt(285,229), pt(283,235), pt(284,243), pt(289,250), pt(297,253), pt(302,252)]),
        .exotic: Grip(top: pt(270,156), outer: pt(306,165), bottom: pt(217,301), paw: [pt(284,219), pt(279,220), pt(270,226), pt(261,234), pt(258,241), pt(258,249), pt(262,255), pt(270,259), pt(277,259)]),
        .golden: Grip(top: pt(271,156), outer: pt(307,165), bottom: pt(220,300), paw: [pt(288,216), pt(282,218), pt(271,225), pt(263,233), pt(260,241), pt(262,249), pt(268,254), pt(276,256), pt(281,254)]),
        .lihua: Grip(top: pt(271,164), outer: pt(306,174), bottom: pt(223,309), paw: [pt(286,226), pt(279,228), pt(269,234), pt(262,242), pt(259,249), pt(260,256), pt(266,263), pt(273,266), pt(280,266)]),
        .bombay: Grip(top: pt(292,150), outer: pt(329,161), bottom: pt(238,300), paw: [pt(313,207), pt(306,211), pt(295,217), pt(286,226), pt(282,233), pt(282,241), pt(286,248), pt(293,252), pt(301,253)]),
        .orange: Grip(top: pt(269,157), outer: pt(304,166), bottom: pt(218,299), paw: [pt(285,215), pt(276,218), pt(268,224), pt(260,233), pt(258,241), pt(261,248), pt(268,254), pt(275,255)]),
        .seal: Grip(top: pt(271,158), outer: pt(305,168), bottom: pt(219,301), paw: [pt(288,216), pt(280,220), pt(271,227), pt(263,234), pt(260,242), pt(261,249), pt(267,254), pt(274,257), pt(279,256)]),
        .silver: Grip(top: pt(273,157), outer: pt(309,167), bottom: pt(222,302), paw: [pt(289,217), pt(282,220), pt(273,226), pt(265,234), pt(262,243), pt(264,250), pt(270,256), pt(277,258), pt(282,256)])
    ]

    private func drawHeldKeyboard() {
        guard let grip = Self.grips[catStyle] else { return }
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let sprite = NSAffineTransform()
        sprite.translateX(by: -106, yBy: -32)
        sprite.scale(by: 212/460)
        sprite.concat()
        let width = pt(grip.outer.x-grip.top.x, grip.outer.y-grip.top.y)
        let length = pt(grip.bottom.x-grip.top.x, grip.bottom.y-grip.top.y)
        let visible = NSBezierPath()
        visible.move(to: grip.top)
        visible.line(to: grip.outer)
        for point in grip.paw { visible.line(to: point) }
        visible.line(to: pt(grip.bottom.x+width.x, grip.bottom.y+width.y))
        visible.line(to: grip.bottom)
        visible.close()
        visible.addClip()
        let deck = NSAffineTransform()
        deck.transformStruct = NSAffineTransformStruct(m11: -length.x/197, m12: -length.y/197,
            m21: width.x/52, m22: width.y/52, tX: grip.bottom.x, tY: grip.bottom.y)
        deck.concat()
        NSGraphicsContext.current!.cgContext.translateBy(x: -50, y: -166)
        drawKeyboard(at: nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill(); dirtyRect.fill(using:.copy)
        NSGraphicsContext.current?.imageInterpolation = .high
        let blend = liftBlend*liftBlend*(3-2*liftBlend)
        if blend < 1 {
            let cg = NSGraphicsContext.current!.cgContext
            cg.saveGState()
            if blend > 0 {
                cg.setAlpha(1-blend)
                cg.beginTransparencyLayer(auxiliaryInfo: nil)
                cg.translateBy(x:0,y:-5*blend)
            }
            drawSeated()
            if blend > 0 { cg.endTransparencyLayer() }
            cg.restoreGState()
        }
        if blend > 0 {
            NSGraphicsContext.saveGraphicsState()
            let pose = NSAffineTransform()
            pose.translateX(by:126,yBy:34+(1-blend)*9)
            pose.rotate(byDegrees:sway)
            pose.concat()
            let context = NSGraphicsContext.current!.cgContext
            context.setAlpha(blend)
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            CatSkin.lifts[catStyle]?.draw(in:CGRect(x:-106,y:-32,width:212,height:212),from:.zero,
                operation:.sourceOver,fraction:1,respectFlipped:true,hints:nil)
            drawHeldMouse()
            drawHeldKeyboard()
            context.endTransparencyLayer()
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private func drawMouse(at center: CGPoint) {
        let shell = CGRect(x:center.x-10,y:center.y-13,width:20,height:27)
        box(shell.offsetBy(dx:0,dy:1.5),9,keyboard.edge)
        box(shell,9,keyboard.cap)
        box(CGRect(x:center.x-0.45,y:shell.maxY-10,width:0.9,height:10),0.45,keyboard.edge)
        box(CGRect(x:center.x-1.3,y:shell.maxY-9.5,width:2.6,height:5.5),1.3,keyboard.legend)
    }

    private func drawHeldMouse() {
        // Trace the underside of each forearm in the 230-point pickup canvas.
        let edge: [CGPoint]
        let center: CGPoint
        switch catStyle {
        case .devonRex:
            edge = [pt(63.5,111), pt(63,119.5), pt(68.5,122.5), pt(79,120.5), pt(84,127), pt(93,129.5), pt(95,119.5)]
            center = pt(81,125.5)
        case .maineCoon:
            edge = [pt(45.5,111.5), pt(44.5,120.5), pt(53,126), pt(60.5,122.5), pt(68,127), pt(78,129), pt(80,118.5)]
            center = pt(62.5,127.5)
        case .siamese:
            edge = [pt(51,109), pt(51,117), pt(58,119.5), pt(68,119.5), pt(75,126.5), pt(82.5,127.5), pt(84.5,117)]
            center = pt(70,124.5)
        case .americanShorthair:
            edge = [pt(48,112), pt(49,122), pt(56.5,124.5), pt(65.5,121.5), pt(71.5,126), pt(81.5,129), pt(85,118.5)]
            center = pt(67.5,126.5)
        case .sphynx:
            edge = [pt(57.5,109.5), pt(56.5,117.5), pt(62,122), pt(72,120.5), pt(77,126), pt(88.5,129), pt(90.5,119)]
            center = pt(74,125.5)
        case .ragdoll:
            edge = [pt(57,109.75), pt(59.25,120.75), pt(70.5,118.5), pt(75.25,120), pt(79.5,124), pt(85.5,123.25), pt(87.75,118)]
            center = pt(75.75,123.75)
        case .exotic:
            edge = [pt(49.75,114.5), pt(51.5,125), pt(58.5,127.5), pt(69.75,125.75), pt(76,129.75), pt(83.5,129.25), pt(87.5,123.75)]
            center = pt(70.5,130)
        case .golden:
            edge = [pt(48.5,110.5), pt(49.75,120.75), pt(56.25,122.5), pt(64,120.75), pt(69,124.25), pt(76.25,125.25), pt(79,119.5)]
            center = pt(66,125.25)
        case .lihua:
            edge = [pt(50.25,115.5), pt(51.25,124.5), pt(57.5,127.75), pt(66.25,125.75), pt(72,130.25), pt(78.25,130.5), pt(81.5,125)]
            center = pt(67.75,130.25)
        case .bombay:
            edge = [pt(58.25,110.25), pt(59.5,118.5), pt(65.75,120.25), pt(74,119.75), pt(80,124.75), pt(86.25,125.25), pt(90.25,119.5)]
            center = pt(75.75,124)
        case .orange:
            edge = [pt(50.25,111), pt(51.25,118.75), pt(57.25,121), pt(64,119.5), pt(69.25,124.5), pt(76.75,124.25), pt(79,118.5)]
            center = pt(66.75,123.75)
        case .seal:
            edge = [pt(49.25,112.75), pt(50.75,121), pt(56,124), pt(65.25,122.25), pt(70.75,126), pt(77.25,126.5), pt(79.75,121)]
            center = pt(67.25,126.75)
        case .silver:
            edge = [pt(49.25,112.25), pt(50.5,120.75), pt(56.25,124), pt(66.25,121.75), pt(72,125.75), pt(78.5,126.5), pt(81.25,120.75)]
            center = pt(68,126.5)
        }
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let sprite = NSAffineTransform()
        sprite.translateX(by:-106,yBy:-32)
        sprite.scale(by:212/230)
        sprite.concat()
        let visible = NSBezierPath()
        visible.move(to:edge[0])
        visible.curve(to:edge[3],controlPoint1:edge[1],controlPoint2:edge[2])
        visible.curve(to:edge[6],controlPoint1:edge[4],controlPoint2:edge[5])
        visible.line(to:pt(edge[6].x,center.y+24))
        visible.line(to:pt(edge[0].x,center.y+24))
        visible.close()
        visible.addClip()
        let tilt = NSAffineTransform()
        tilt.translateX(by:center.x,yBy:center.y)
        tilt.rotate(byDegrees:-16)
        tilt.concat()
        drawMouse(at:.zero)
    }

    private func drawKeyboard(at now: TimeInterval?) {
        box(CGRect(x:50,y:166,width:197,height:52),6,keyboard.base)
        let radius: CGFloat
        switch keyboardStyle {
        case .sakura, .matcha: radius = 3.6
        case .glacier, .retro: radius = 1
        default: radius = 2
        }
        switch keyboardStyle {
        case .glacier:
            box(CGRect(x:52,y:167,width:193,height:1.5),1,.white.withAlphaComponent(0.8))
        case .retro:
            for i in 0..<3 { box(CGRect(x:57+CGFloat(i)*5,y:173,width:3,height:2),1,keyboard.legend) }
        case .walnut:
            for y in [168,175,211,215] { box(CGRect(x:54,y:y,width:189,height:1),0.5,keyboard.edge) }
        default: break
        }
        for c in KeyCap.board {
            let down = now.map { time in strokes.contains { $0.code == c.code && time-$0.time < 0.09 } } ?? false
            let accent = c.code == 36 || (c.code == 49 && radius != 2) || (keyboardStyle == .sakura && c.code <= 2)
            box(c.rect.offsetBy(dx:0,dy:1.2),radius,keyboard.edge)
            box(c.rect.offsetBy(dx:0,dy:down ? 1 : 0),radius,(down || accent) ? keyboard.accent : keyboard.cap)
            NSGraphicsContext.saveGraphicsState()
            let orientation = NSAffineTransform()
            orientation.translateX(by: c.center.x, yBy: c.center.y)
            orientation.rotate(byDegrees: 180)
            orientation.concat()
            label(c.legend,.zero,5.8,keyboard.legend)
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private func bounce(_ age: TimeInterval, duration: TimeInterval, height: CGFloat) -> CGFloat {
        guard age >= 0 else { return 0 }
        let phase = age/duration
        let t = phase < 1 ? phase : (phase-1)/0.45
        guard t < 1 else { return 0 }
        return 4*t*(1-t)*height*(phase < 1 ? 1 : 0.20)
    }

    private func drawSeated() {
        let now = CACurrentMediaTime()
        let age = knockStarted.map { now-$0 } ?? 1
        let deckHop = bounce(age,duration:0.22,height:6)
        let mouseHop = bounce(age-0.018,duration:0.29,height:11)
        let surprise = max(0,min(1,age/0.07,(0.55-age)/0.28))

        drawBody()
        for e in cat.eyes {
            let x = e.x+gaze.x*0.44+head.x, y = e.y+gaze.y*0.48+head.y
            let radius = 2.5+1.1*surprise
            box(CGRect(x:x-radius,y:y-3.3,width:2*radius,height:6.6),radius,shade(0x252c35))
            box(CGRect(x:x-1.4,y:y-2,width:1.4,height:1.4),0.7,.white)
        }
        NSGraphicsContext.saveGraphicsState()
        let deck = NSAffineTransform()
        deck.translateX(by:deckRect.minX, yBy:deckRect.minY-deckHop)
        deck.scale(by:deckScale)
        deck.translateX(by:-50,yBy:-166)
        deck.concat()
        drawKeyboard(at: now)
        NSGraphicsContext.restoreGraphicsState()
        drawMouse(at:pt(mouse.x,mouse.y-mouseHop))
        for side in paws.indices {
            let pressure = typing ? max(0, 1-abs(now-taps[side]-0.068)/0.055) : 0
            drawForeleg(side:side,pressure:pressure,hop:side == 0 && !typing ? mouseHop : deckHop)
        }
        for s in strokes {
            let phase = min(1,(now-s.time)/0.55)
            let key = deckPoint(s.point)
            let center = pt(key.x,key.y-12-29*phase)
            let opacity = min(1,(1-phase)*3)
            box(CGRect(x:center.x-9,y:center.y-8,width:18,height:16),4,keyboard.cap.withAlphaComponent(opacity))
            label(s.label,center,10,keyboard.legend.withAlphaComponent(opacity))
        }
    }
}
