import SwiftUI
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

func generateQRCode(from string: String) -> NSImage? {
    guard !string.isEmpty else { return nil }

    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "M"

    guard let outputImage = filter.outputImage else { return nil }
    let transform = CGAffineTransform(scaleX: 10, y: 10)
    let scaledImage = outputImage.transformed(by: transform)

    let context = CIContext()
    guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
    return NSImage(cgImage: cgImage, size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height))
}

struct QRCodeGeneratorView: View {
    @State private var input = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "qrcode")
                Text("QR Code")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.secondary)

            TextField("Enter text or URL", text: $input)
                .textFieldStyle(.roundedBorder)

            if let image = generateQRCode(from: input) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}
