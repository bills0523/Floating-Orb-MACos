import Foundation
import AppKit
import SwiftUI
import Combine

final class ClipboardManager: ObservableObject {
    @Published var items: [String] = []

    private let pasteboard = NSPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int

    init() {
        lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollPasteboard()
        }
    }

    private func pollPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard let value = pasteboard.string(forType: .string) else { return }
        add(value)
    }

    private func add(_ value: String) {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        items.removeAll { $0 == text }
        items.insert(text, at: 0)
        if items.count > 10 {
            items = Array(items.prefix(10))
        }
    }

    func recopy(_ value: String) {
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        add(value)
    }
}

struct ClipboardHistoryView: View {
    @ObservedObject var manager: ClipboardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.on.clipboard")
                Text("Clipboard")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.secondary)

            if manager.items.isEmpty {
                Text("No copied text yet")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(manager.items, id: \.self) { value in
                            Button {
                                manager.recopy(value)
                            } label: {
                                Text(value)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(8)
                                    .background(.thinMaterial.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
        }
    }
}
