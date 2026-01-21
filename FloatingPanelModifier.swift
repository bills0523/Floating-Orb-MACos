import SwiftUI
import AppKit

/// SwiftUI helper to move the hosting window with a drag and snap it to the nearest screen edge.
struct FloatingPanelModifier: ViewModifier {
    @State private var window: NSWindow?
    @State private var initialOrigin: NSPoint = .zero

    func body(content: Content) -> some View {
        content
            .background(WindowResolver { resolvedWindow in
                window = resolvedWindow
            })
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        guard let window else { return }
                        if initialOrigin == .zero {
                            initialOrigin = window.frame.origin
                        }
                        // SwiftUI drag y+ is down; AppKit window y+ is up.
                        let target = NSPoint(x: initialOrigin.x + value.translation.width,
                                             y: initialOrigin.y - value.translation.height)
                        window.setFrameOrigin(target)
                    }
                    .onEnded { _ in
                        guard let window else { return }
                        initialOrigin = .zero
                        snap(window: window)
                    }
            )
    }

    private func snap(window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let frame = window.frame
        let screenFrame = screen.visibleFrame

        let left = abs(frame.minX - screenFrame.minX)
        let right = abs(screenFrame.maxX - frame.maxX)
        let top = abs(screenFrame.maxY - frame.maxY)
        let bottom = abs(frame.minY - screenFrame.minY)

        let nearest = min(left, right, top, bottom)
        var origin = frame.origin

        if nearest == left {
            origin.x = screenFrame.minX
        } else if nearest == right {
            origin.x = screenFrame.maxX - frame.width
        } else if nearest == top {
            origin.y = screenFrame.maxY - frame.height
        } else {
            origin.y = screenFrame.minY
        }

        window.setFrameOrigin(origin)
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
    func floatingPanelSnap() -> some View {
        modifier(FloatingPanelModifier())
    }
}
