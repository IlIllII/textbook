import Cocoa
import AVFoundation

public enum EventType: Int {
    case keyPress = 0
    case mouseMove = 1
    case mouseClick = 2
}

// public struct Event {
//     var type: EventType
//     var keyCode: Int32
//     var mouseX: Float
//     var mouseY: Float
//     var mouseButton: Int32
//     var isPressed: Bool
// }

var globalPlatformLayer: PlatformLayer?
var eventQeueue: [Event] = []
var player: AVAudioPlayer?


class PlatformLayer: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var customView: CustomView?

    override init() {
        super.init()
        let app = NSApplication.shared
        app.delegate = self
        setupWindow()
    }
    
    func setupWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), 
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], 
                          backing: .buffered, 
                          defer: false)
        window?.center()
        window?.title = "Test Window"
        
        customView = CustomView(frame: window!.contentRect(forFrameRect: window!.frame))
        window?.contentView = customView
        window?.makeKeyAndOrderFront(nil)
        window?.isReleasedWhenClosed = false
    }
    
    func resizeWindow(width: Int, height: Int) {
        DispatchQueue.main.async {
            self.window?.setContentSize(NSSize(width: CGFloat(width), height: CGFloat(height)))
        }
    }
    
    func setWindowTitle(_ title: String) {
        DispatchQueue.main.async {
            self.window?.title = title
        }
    }

    // TODO: Add more stuffs
}

class CustomView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let context = NSGraphicsContext.current?.cgContext {
            context.setFillColor(NSColor.red.cgColor)
            context.fill(CGRect(x: 10, y: 10, width: 100, height: 100))
            // TODO: Create proper draw methods, such as lines!
        }
    }

    // TODO: Refactor event handling

    override func keyDown(with event: NSEvent) {
        handleKeyPress(Int32(event.keyCode), true)
    }

    override func keyUp(with event: NSEvent) {
        handleKeyPress(Int32(event.keyCode), false)
    }

    override func mouseDown(with event: NSEvent) {
        handleMouseClick(Float(event.locationInWindow.x), Float(event.locationInWindow.y), 0, true)
    }

    override func mouseUp(with event: NSEvent) {
        handleMouseClick(Float(event.locationInWindow.x), Float(event.locationInWindow.y), 0, false)
    }

    override func mouseDragged(with event: NSEvent) {
        handleMouseMove(Float(event.locationInWindow.x), Float(event.locationInWindow.y))
    }

    override func mouseMoved(with event: NSEvent) {
        handleMouseMove(Float(event.locationInWindow.x), Float(event.locationInWindow.y))
    }

    override func rightMouseDown(with event: NSEvent) {
        handleMouseClick(Float(event.locationInWindow.x), Float(event.locationInWindow.y), 1, true)
    }

    override func rightMouseUp(with event: NSEvent) {
        handleMouseClick(Float(event.locationInWindow.x), Float(event.locationInWindow.y), 1, false)
    }

    override func otherMouseDown(with event: NSEvent) {
        handleMouseClick(Float(event.locationInWindow.x), Float(event.locationInWindow.y), 2, true)
    }

    override func otherMouseUp(with event: NSEvent) {
        handleMouseClick(Float(event.locationInWindow.x), Float(event.locationInWindow.y), 2, false)
    }

    override func scrollWheel(with event: NSEvent) {
        // Handle scroll wheel event
    }

    override func rightMouseDragged(with event: NSEvent) {
        handleMouseMove(Float(event.locationInWindow.x), Float(event.locationInWindow.y))
    }

    override func otherMouseDragged(with event: NSEvent) {
        handleMouseMove(Float(event.locationInWindow.x), Float(event.locationInWindow.y))
    }


    func handleKeyPress(_ keyCode: Int32, _ isPressed: Bool) {
        let event = Event(type: 1, keyCode: keyCode, mouseX: 0, mouseY: 0, mouseButton: 0, isPressed: 1)
        eventQeueue.append(event)
    }

    func handleMouseMove(_ mouseX: Float, _ mouseY: Float) {
        let event = Event(type: 1, keyCode: 0, mouseX: Int32(mouseX), mouseY: Int32(mouseY), mouseButton: 0, isPressed: 1)
        eventQeueue.append(event)
    }

    func handleMouseClick(_ mouseX: Float, _ mouseY: Float, _ mouseButton: Int32, _ isPressed: Bool) {
        let event = Event(type: 1, keyCode: 0, mouseX: Int32(mouseX), mouseY: Int32(mouseY), mouseButton: mouseButton, isPressed: 1)
        eventQeueue.append(event)
    }
}


// TODO: Think about API
@_cdecl("initializePlatformLayer")
public func initializePlatformLayer() {
    globalPlatformLayer = PlatformLayer()
    NSApplication.shared.run()
}

@_cdecl("resizeWindow")
public func resizeWindow(width: Int32, height: Int32) {
    DispatchQueue.main.async {
        globalPlatformLayer?.resizeWindow(width: Int(width), height: Int(height))
    }
}

@_cdecl("setWindowTitle")
public func setWindowTitle(title: UnsafePointer<CChar>) {
    let string = String(cString: title)
    DispatchQueue.main.async {
        globalPlatformLayer?.setWindowTitle(string)
    }
}

@_cdecl("playSound")
public func playSound(filename: UnsafePointer<CChar>) {
    let soundName = String(cString: filename)
    guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
    do {
        player = try AVAudioPlayer(contentsOf: url)
        player?.play()
    } catch let error {
        print(error.localizedDescription)
    }
}

@_cdecl("pollEvents")
public func pollEvents() -> UnsafeMutablePointer<Event>? {
    if eventQeueue.isEmpty {
        return nil
    }
    
    let event = eventQeueue.removeFirst()
    let pointer = UnsafeMutablePointer<Event>.allocate(capacity: 1)
    pointer.pointee = event
    return pointer
}
