import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class FloatingReferenceWindowManager: NSObject, NSWindowDelegate {
    static let shared = FloatingReferenceWindowManager()
    private var windows: [NSWindow] = []

    private override init() {
        super.init()
    }

    func openImage(_ image: NSImage) {
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 420, height: 320),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.delegate = self

        window.contentView = NSHostingView(
            rootView: ReferenceImageWindowContent(image: image) { [weak window] in
                window?.close()
            }
        )
        windows.append(window)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }
        windows.removeAll { $0 == closingWindow }
    }
}

struct FloatingReferenceImageToolView: View {
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Drop an image to open a floating reference window.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial.opacity(0.45))
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.rectangle.on.folder")
                            .font(.system(size: 24, weight: .semibold))
                        Text("Drag Image Here")
                            .font(.system(size: 13, weight: .semibold))
                        Text("PNG, JPG, HEIC, TIFF")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isDropTargeted ? Color.accentColor : Color.white.opacity(0.2), lineWidth: 1.5)
                }
                .frame(height: 180)
                .onDrop(
                    of: [
                        UTType.fileURL.identifier,
                        UTType.image.identifier
                    ],
                    isTargeted: $isDropTargeted,
                    perform: handleDrop(providers:)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      let image = NSImage(contentsOf: url) else { return }
                DispatchQueue.main.async {
                    FloatingReferenceWindowManager.shared.openImage(image)
                }
            }
            return true
        }

        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data, let image = NSImage(data: data) else { return }
                DispatchQueue.main.async {
                    FloatingReferenceWindowManager.shared.openImage(image)
                }
            }
            return true
        }

        return false
    }
}

private struct ReferenceImageWindowContent: View {
    let image: NSImage
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .background(.ultraThinMaterial.opacity(0.08))

            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(8)
        }
        .background(.ultraThinMaterial.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .padding(6)
        .contextMenu {
            Button("Close", role: .destructive, action: onClose)
        }
    }
}
