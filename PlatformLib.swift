import Cocoa
import AVFoundation
import Foundation

public enum EventType: Int {
    case keyPress = 0
    case mouseMove = 1
    case mouseClick = 2
}

var globalPlatformLayer: PlatformLayer?
var eventQeueue: [Event] = []
var player: AVAudioPlayer?


class PlatformLayer: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var customView: CustomView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
    }

    func setupWindow() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.delegate = self

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
        NSApplication.shared.activate(ignoringOtherApps: true)
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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class CustomView: NSView {
    var drawingCommands: [() -> Void] = []

    func addDrawingCommand(_ command: @escaping () -> Void) {
        drawingCommands.append(command)
        self.setNeedsDisplay(self.bounds)
    }

    func drawPath(points: [CGPoint], outlineColor: NSColor, filled: Bool, fillColor: NSColor, lineThickness: CGFloat) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let path = CGMutablePath()
        if let firstPoint = points.first {
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }

        context.addPath(path)

        if filled {
            context.setFillColor(fillColor.cgColor)
            context.fillPath()
        }

        context.setStrokeColor(outlineColor.cgColor)
        context.setLineWidth(lineThickness)
        context.addPath(path)
        context.strokePath()
    }

    func drawCircle(center: CGPoint, radius: CGFloat, outlineColor: NSColor, filled: Bool, fillColor: NSColor, lineThickness: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        drawPath(points: [CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.maxY)], outlineColor: outlineColor, filled: filled, fillColor: fillColor, lineThickness: lineThickness)
    }

    func drawLine(from startPoint: CGPoint, to endPoint: CGPoint, color: NSColor, lineThickness: CGFloat) {
        drawPath(points: [startPoint, endPoint], outlineColor: color, filled: false, fillColor: .clear, lineThickness: lineThickness)
    }    

    func drawRectangle(rect: CGRect, outlineColor: NSColor, filled: Bool, fillColor: NSColor, lineThickness: CGFloat) {
        addDrawingCommand {
            print("Drawing rectangle")
            print(rect)
            print(fillColor)
            guard let context = NSGraphicsContext.current?.cgContext else { return }
            if filled {
                context.setFillColor(fillColor.cgColor)
                context.fill(rect)
            }
            context.setStrokeColor(outlineColor.cgColor)
            context.setLineWidth(lineThickness)
            context.stroke(rect)
        }
    }

    func drawEllipse(in rect: CGRect, outlineColor: NSColor, filled: Bool, fillColor: NSColor, lineThickness: CGFloat) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        if filled {
            context.setFillColor(fillColor.cgColor)
            context.fillEllipse(in: rect)
        }
        context.setStrokeColor(outlineColor.cgColor)
        context.setLineWidth(lineThickness)
        context.strokeEllipse(in: rect)
    }

    func renderText(text: String, position: CGPoint, color: NSColor, fontSize: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: color
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: position)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawingCommands.forEach { $0() }
        drawingCommands.removeAll()
        // if let context = NSGraphicsContext.current?.cgContext {
        //     context.setFillColor(NSColor.red.cgColor)
        //     context.fill(CGRect(x: 10, y: 10, width: 100, height: 100))
        //     // TODO: Create proper draw methods, such as lines!
        // }
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


// @_cdecl("startCustomRunLoop")
// public func startCustomRunLoop(callback: @escaping () -> Void) {
//     DispatchQueue.main.async {
//         let app = NSApplication.shared
//         app.setActivationPolicy(.regular)
//         globalPlatformLayer = PlatformLayer()

//         var shouldKeepRunning = true
//         while shouldKeepRunning {
//             let untilDate = Date(timeIntervalSinceNow: 0.01) // Adjust as needed
//             if let event = app.nextEvent(matching: .any, until: untilDate, inMode: .default, dequeue: true) {
//                 app.sendEvent(event)
//             }
//             // Call back to Python code here
//             callback()
//         }
//     }
// }

// TODO: Think about API
@_cdecl("initializePlatformLayer")
public func initializePlatformLayer() {
    print("Initializing platform layer")
    DispatchQueue.main.async {
        if globalPlatformLayer == nil {
            globalPlatformLayer = PlatformLayer()
            globalPlatformLayer?.applicationDidFinishLaunching(Notification(name: Notification.Name("What")))
        }
    }
    print("Platform layer initialized")
    // DispatchQueue.global(qos: .background).async {
    //     let app = NSApplication.shared
    //     app.setActivationPolicy(.regular)

    //     DispatchQueue.main.async {
    //         globalPlatformLayer = PlatformLayer()
    //     }
    //     app.run()
    // }
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

@_cdecl("drawRectangle")
public func drawRectangle(x: Float, y: Float, width: Float, height: Float, outlineColor: PythonColor, filled: Int32, fillColor: PythonColor, lineThickness: Float) {
    let convertedFillColor = NSColor(
        red: CGFloat(fillColor.r * 100000),
        green: CGFloat(fillColor.g),
        blue: CGFloat(fillColor.b),
        alpha: CGFloat(fillColor.a)
    )
    let convertedOutlineColor = NSColor(
        red: CGFloat(outlineColor.r),
        green: CGFloat(outlineColor.g),
        blue: CGFloat(outlineColor.b),
        alpha: CGFloat(outlineColor.a)
    )
    DispatchQueue.main.async {
        globalPlatformLayer?.customView?.drawRectangle(rect: CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height)), outlineColor: convertedOutlineColor, filled: true, fillColor: convertedFillColor, lineThickness: CGFloat(lineThickness))
    }
}

@_cdecl("drawCircle")
public func drawCircle(centerX: Float, centerY: Float, radius: Float, outlineColor: PythonColor, filled: Int32, fillColor: PythonColor, lineThickness: Float) {
    let convertedFillColor = NSColor(
        red: CGFloat(fillColor.r),
        green: CGFloat(fillColor.g),
        blue: CGFloat(fillColor.b),
        alpha: CGFloat(fillColor.a)
    )
    let convertedOutlineColor = NSColor(
        red: CGFloat(outlineColor.r),
        green: CGFloat(outlineColor.g),
        blue: CGFloat(outlineColor.b),
        alpha: CGFloat(outlineColor.a)
    )
    DispatchQueue.main.async {
        globalPlatformLayer?.customView?.drawCircle(center: CGPoint(x: CGFloat(centerX), y: CGFloat(centerY)), radius: CGFloat(radius), outlineColor: convertedOutlineColor, filled: filled == 1, fillColor: convertedFillColor, lineThickness: CGFloat(lineThickness))
    }
}

@_cdecl("drawLine")
public func drawLine(startX: Float, startY: Float, endX: Float, endY: Float, color: PythonColor, lineThickness: Float) {
    let convertedColor = NSColor(
        red: CGFloat(color.r),
        green: CGFloat(color.g),
        blue: CGFloat(color.b),
        alpha: CGFloat(color.a)
    )
    DispatchQueue.main.async {
        globalPlatformLayer?.customView?.drawLine(from: CGPoint(x: CGFloat(startX), y: CGFloat(startY)), to: CGPoint(x: CGFloat(endX), y: CGFloat(endY)), color: convertedColor, lineThickness: CGFloat(lineThickness))
    }
}

@_cdecl("drawEllipse")
public func drawEllipse(x: Float, y: Float, width: Float, height: Float, outlineColor: PythonColor, filled: Int32, fillColor: PythonColor, lineThickness: Float) {
    let convertedFillColor = NSColor(
        red: CGFloat(fillColor.r),
        green: CGFloat(fillColor.g),
        blue: CGFloat(fillColor.b),
        alpha: CGFloat(fillColor.a)
    )
    let convertedOutlineColor = NSColor(
        red: CGFloat(outlineColor.r),
        green: CGFloat(outlineColor.g),
        blue: CGFloat(outlineColor.b),
        alpha: CGFloat(outlineColor.a)
    )
    DispatchQueue.main.async {
        globalPlatformLayer?.customView?.drawEllipse(in: CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height)), outlineColor: convertedOutlineColor, filled: filled == 1, fillColor: convertedFillColor, lineThickness: CGFloat(lineThickness))
    }
}

@_cdecl("renderText")
public func renderText(text: UnsafePointer<CChar>, x: Float, y: Float, color: PythonColor, fontSize: Float) {
    let string = String(cString: text)
    let convertedColor = NSColor(
        red: CGFloat(color.r),
        green: CGFloat(color.g),
        blue: CGFloat(color.b),
        alpha: CGFloat(color.a)
    )
    DispatchQueue.main.async {
        globalPlatformLayer?.customView?.renderText(text: string, position: CGPoint(x: CGFloat(x), y: CGFloat(y)), color: convertedColor, fontSize: CGFloat(fontSize))
    }
}

@_cdecl("drawPath")
public func drawPath(points: UnsafeMutablePointer<CGPoint>, count: Int32, outlineColor: PythonColor, filled: Int32, fillColor: PythonColor, lineThickness: Float) {
    let convertedFillColor = NSColor(
        red: CGFloat(fillColor.r),
        green: CGFloat(fillColor.g),
        blue: CGFloat(fillColor.b),
        alpha: CGFloat(fillColor.a)
    )
    let convertedOutlineColor = NSColor(
        red: CGFloat(outlineColor.r),
        green: CGFloat(outlineColor.g),
        blue: CGFloat(outlineColor.b),
        alpha: CGFloat(outlineColor.a)
    )
    let swiftPoints = Array(UnsafeBufferPointer(start: points, count: Int(count)))
    DispatchQueue.main.async {
        globalPlatformLayer?.customView?.drawPath(points: swiftPoints, outlineColor: convertedOutlineColor, filled: filled == 1, fillColor: convertedFillColor, lineThickness: CGFloat(lineThickness))
    }
}

@_cdecl("processEvents")
public func processEvents() {
    let app = NSApplication.shared
    while let event = app.nextEvent(matching: .any, until: Date.distantPast, inMode: .default, dequeue: true) {
        app.sendEvent(event)
    }
}

