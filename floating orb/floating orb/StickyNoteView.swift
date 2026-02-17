import SwiftUI
import AppKit

struct StickyNoteView: View {
    @AppStorage("scratchpad_text") private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextEditor(text: $text)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .frame(minHeight: 170)
                .padding(8)
                .background(.thinMaterial.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 8) {
                Button("Copy All") {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(text, forType: .string)
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    text = ""
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
