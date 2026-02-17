import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ImageConverterView: View {
    @State private var isTargeted = false
    @State private var message = "Drop an image to convert to JPG"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial.opacity(0.4))
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.checkmark")
                            .font(.system(size: 24, weight: .semibold))
                        Text("Drop Image Here")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Will save JPG to Downloads")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isTargeted ? Color.accentColor : Color.white.opacity(0.2), lineWidth: 1.5)
                }
                .frame(height: 170)
                .onDrop(
                    of: [UTType.fileURL.identifier, UTType.image.identifier],
                    isTargeted: $isTargeted,
                    perform: convertDroppedImage(providers:)
                )

            Text(message)
                .font(.system(size: 12, weight: .medium))
        }
    }

    private func convertDroppedImage(providers: [NSItemProvider]) -> Bool {
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      let image = NSImage(contentsOf: url) else { return }
                saveJPG(image: image, sourceName: url.deletingPathExtension().lastPathComponent)
            }
            return true
        }

        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data, let image = NSImage(data: data) else { return }
                saveJPG(image: image, sourceName: "converted_image")
            }
            return true
        }
        return false
    }

    private func saveJPG(image: NSImage, sourceName: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpgData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            DispatchQueue.main.async { message = "Conversion failed." }
            return
        }

        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        let targetURL = downloads.appendingPathComponent("\(sourceName).jpg")

        do {
            try jpgData.write(to: targetURL, options: .atomic)
            DispatchQueue.main.async { message = "Saved to Downloads!" }
        } catch {
            DispatchQueue.main.async { message = "Save failed." }
        }
    }
}
