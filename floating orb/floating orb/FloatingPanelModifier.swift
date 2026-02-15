import SwiftUI
import AppKit

/// SwiftUI helper to move the hosting window with a drag; no snapping.
struct FloatingPanelModifier: ViewModifier {
    @State private var window: NSWindow?
    @State private var dragStartOrigin: NSPoint?

    func body(content: Content) -> some View {
        content
            .background(WindowResolver { resolvedWindow in
                window = resolvedWindow
            })
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        guard let window else { return }
                        if dragStartOrigin == nil {
                            dragStartOrigin = window.frame.origin
                        }
                        guard let origin = dragStartOrigin else { return }
                        // SwiftUI drag y+ is down; AppKit window y+ is up.
                        let target = NSPoint(x: origin.x + value.translation.width,
                                             y: origin.y - value.translation.height)
                        window.setFrameOrigin(target)
                    }
                    .onEnded { _ in
                        dragStartOrigin = nil
                    }
            )
    }
}

/// Injects the hosting NSWindow into SwiftUI hierarchy.
private struct WindowResolver: NSViewRepresentable {
    var onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            onResolve(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onResolve(nsView.window)
        }
    }
}

extension View {
    func floatingPanelDraggable() -> some View {
        modifier(FloatingPanelModifier())
    }
}
