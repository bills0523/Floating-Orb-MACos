import SwiftUI
import AppKit

struct ClipboardStatsView: View {
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button("Refresh") { refreshClipboard() }
                    .buttonStyle(.borderedProminent)
                Spacer()
                Text("Clipboard")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            statRow(label: "Character Count", value: "\(text.count)")
            statRow(label: "Word Count", value: "\(wordCount)")
            statRow(label: "Sentence Count", value: "\(sentenceCount)")
            statRow(label: "Estimated Read Time", value: readTime)
        }
        .onAppear { refreshClipboard() }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
        .padding(.vertical, 3)
    }

    private var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var sentenceCount: Int {
        let separators = CharacterSet(charactersIn: ".!?")
        let parts = text.components(separatedBy: separators)
        return parts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var readTime: String {
        let minutes = max(1, Int(ceil(Double(wordCount) / 200.0)))
        return "\(minutes) min"
    }

    private func refreshClipboard() {
        text = NSPasteboard.general.string(forType: .string) ?? ""
    }
}
