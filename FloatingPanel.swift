import Cocoa
import SwiftUI

/// Borderless, transparent, always-on-top panel hosting SwiftUI content.
final class FloatingPanel<Content: View>: NSPanel, NSWindowDelegate {
    private let hostingController: NSHostingController<Content>

    init(contentRect: NSRect = NSRect(x: 120, y: 120, width: 120, height: 120),
         content: Content) {
        self.hostingController = NSHostingController(rootView: content)

        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .moveToActiveSpace]
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        hasShadow = true
        backgroundColor = .clear
        isOpaque = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        worksWhenModal = true
        animationBehavior = .none
        delegate = self

        contentViewController = hostingController
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // Keep the panel floating above everything else.
    func windowDidBecomeKey(_ notification: Notification) {
        level = .floating
    }

    func windowDidResignKey(_ notification: Notification) {
        level = .floating
    }
}
