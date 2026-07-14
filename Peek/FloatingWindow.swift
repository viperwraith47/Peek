import Cocoa

class FloatingWindow: NSWindow {
    private var isResizing = false
    private var resizeEdge: NSRectEdge?
    private var resizeStartPoint: NSPoint = .zero
    private var resizeStartFrame: NSRect = .zero
    private let minDimension: CGFloat = 150
    private let maxDimension: CGFloat = 800
    private let edgeThreshold: CGFloat = 8

    convenience init(contentRect: NSRect) {
        self.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
    }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }

    private func setupWindow() {
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override var isResizable: Bool { true }

    private func edgeAtPoint(_ point: NSPoint, in view: NSView) -> NSRectEdge? {
        let bounds = view.bounds
        let left = abs(point.x - bounds.minX)
        let right = abs(point.x - bounds.maxX)
        let top = abs(point.y - bounds.maxY)
        let bottom = abs(point.y - bounds.minY)

        let minDist = min(left, right, top, bottom)
        guard minDist < edgeThreshold else { return nil }

        if minDist == left { return .minX }
        if minDist == right { return .maxX }
        if minDist == top { return .maxY }
        return .minY
    }

    override func mouseDown(with event: NSEvent) {
        guard let contentView else { super.mouseDown(with: event); return }
        let locationInView = contentView.convert(event.locationInWindow, from: nil)

        if let edge = edgeAtPoint(locationInView, in: contentView) {
            isResizing = true
            resizeEdge = edge
            resizeStartPoint = NSEvent.mouseLocation
            resizeStartFrame = frame
        } else {
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        if isResizing, let edge = resizeEdge {
            let currentPoint = NSEvent.mouseLocation
            let deltaX = currentPoint.x - resizeStartPoint.x
            let deltaY = currentPoint.y - resizeStartPoint.y

            var newFrame = resizeStartFrame

            switch edge {
            case .minX:
                let clampedDelta = min(deltaX, resizeStartFrame.width - minDimension)
                newFrame.origin.x = resizeStartFrame.origin.x + clampedDelta
                newFrame.size.width = resizeStartFrame.width - clampedDelta
            case .maxX:
                let clampedDelta = max(deltaX, -(resizeStartFrame.width - minDimension))
                newFrame.size.width = min(maxDimension, resizeStartFrame.width + clampedDelta)
            case .maxY:
                let clampedDelta = max(deltaY, -(resizeStartFrame.height - minDimension))
                newFrame.size.height = min(maxDimension, resizeStartFrame.height + clampedDelta)
            case .minY:
                let clampedDelta = min(deltaY, resizeStartFrame.height - minDimension)
                newFrame.origin.y = resizeStartFrame.origin.y + clampedDelta
                newFrame.size.height = resizeStartFrame.height - clampedDelta
            @unknown default:
                break
            }

            newFrame.size.width = max(minDimension, newFrame.size.width)
            newFrame.size.height = max(minDimension, newFrame.size.height)

            super.setFrame(newFrame, display: true, animate: false)
            StateManager.shared.saveWindowPosition(frame.origin)
            StateManager.shared.saveWindowSize(frame.size)
        } else {
            super.mouseDragged(with: event)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if isResizing {
            isResizing = false
            resizeEdge = nil
            StateManager.shared.saveWindowPosition(frame.origin)
            StateManager.shared.saveWindowSize(frame.size)
        } else {
            super.mouseUp(with: event)
        }
    }
}
