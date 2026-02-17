import Foundation
import Combine
import SwiftUI // for move(fromOffsets:toOffset:)

struct OrbAction: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case goHome
        case desktopIcons
        case appearance
        case command
        case finder
        case volumeControl
        case clipboard
        case qrCode
        case latency
        case referenceImage
        case dateUtility
        case quickTimer
        case stickyNote
        case screenRuler
        case decisionMaker
        case imageConverter
        case textStats
    }

    var id: String
    var title: String
    var systemImage: String
    var isEnabled: Bool
    var kind: Kind

    static let `default`: [OrbAction] = [
        OrbAction(id: "desktopIcons", title: "Desktop", systemImage: "eye", isEnabled: true, kind: .desktopIcons),
        OrbAction(id: "appearance", title: "Theme", systemImage: "sun.max.fill", isEnabled: true, kind: .appearance),
        OrbAction(id: "clipboard", title: "Clipboard", systemImage: "doc.on.clipboard", isEnabled: true, kind: .clipboard),
        OrbAction(id: "qrcode", title: "QR Code", systemImage: "qrcode", isEnabled: true, kind: .qrCode),
        OrbAction(id: "latency", title: "Latency", systemImage: "dot.radiowaves.left.and.right", isEnabled: true, kind: .latency),
        OrbAction(id: "referenceImage", title: "Reference", systemImage: "photo.on.rectangle.angled", isEnabled: true, kind: .referenceImage),
        OrbAction(id: "dateUtility", title: "Date Tool", systemImage: "calendar.badge.clock", isEnabled: true, kind: .dateUtility),
        OrbAction(id: "quickTimer", title: "Timer", systemImage: "timer", isEnabled: true, kind: .quickTimer),
        OrbAction(id: "stickyNote", title: "Scratchpad", systemImage: "note.text", isEnabled: true, kind: .stickyNote),
        OrbAction(id: "screenRuler", title: "Ruler", systemImage: "ruler", isEnabled: true, kind: .screenRuler),
        OrbAction(id: "decisionMaker", title: "Decide", systemImage: "dice", isEnabled: true, kind: .decisionMaker),
        OrbAction(id: "imageConverter", title: "Convert", systemImage: "photo.badge.checkmark", isEnabled: true, kind: .imageConverter),
        OrbAction(id: "textStats", title: "Text Stats", systemImage: "textformat.abc", isEnabled: true, kind: .textStats),
        OrbAction(id: "command", title: "Command", systemImage: "terminal", isEnabled: true, kind: .command),
        OrbAction(id: "finder", title: "Finder", systemImage: "folder", isEnabled: true, kind: .finder),
        OrbAction(id: "volume", title: "Volume", systemImage: "speaker.wave.2.fill", isEnabled: true, kind: .volumeControl)
    ]
}

final class ActionStore: ObservableObject {
    @Published var actions: [OrbAction] {
        didSet { persist() }
    }

    private let storageKey = "orb.actions"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([OrbAction].self, from: data) {
            // Migration: remove legacy Desktop action and add appearance action if missing.
            var migrated = decoded.filter { $0.kind != .goHome }
            if !migrated.contains(where: { $0.kind == .desktopIcons }) {
                migrated.insert(OrbAction(id: "desktopIcons", title: "Desktop", systemImage: "eye", isEnabled: true, kind: .desktopIcons), at: 0)
            }
            if !migrated.contains(where: { $0.kind == .appearance }) {
                migrated.insert(OrbAction(id: "appearance", title: "Theme", systemImage: "sun.max.fill", isEnabled: true, kind: .appearance), at: 1)
            }
            if !migrated.contains(where: { $0.kind == .clipboard }) {
                migrated.insert(OrbAction(id: "clipboard", title: "Clipboard", systemImage: "doc.on.clipboard", isEnabled: true, kind: .clipboard), at: 2)
            }
            if !migrated.contains(where: { $0.kind == .qrCode }) {
                migrated.insert(OrbAction(id: "qrcode", title: "QR Code", systemImage: "qrcode", isEnabled: true, kind: .qrCode), at: 3)
            }
            if !migrated.contains(where: { $0.kind == .latency }) {
                migrated.insert(OrbAction(id: "latency", title: "Latency", systemImage: "dot.radiowaves.left.and.right", isEnabled: true, kind: .latency), at: 4)
            }
            if !migrated.contains(where: { $0.kind == .referenceImage }) {
                migrated.insert(OrbAction(id: "referenceImage", title: "Reference", systemImage: "photo.on.rectangle.angled", isEnabled: true, kind: .referenceImage), at: 5)
            }
            if !migrated.contains(where: { $0.kind == .dateUtility }) {
                migrated.insert(OrbAction(id: "dateUtility", title: "Date Tool", systemImage: "calendar.badge.clock", isEnabled: true, kind: .dateUtility), at: 6)
            }
            if !migrated.contains(where: { $0.kind == .quickTimer }) {
                migrated.insert(OrbAction(id: "quickTimer", title: "Timer", systemImage: "timer", isEnabled: true, kind: .quickTimer), at: 7)
            }
            if !migrated.contains(where: { $0.kind == .stickyNote }) {
                migrated.insert(OrbAction(id: "stickyNote", title: "Scratchpad", systemImage: "note.text", isEnabled: true, kind: .stickyNote), at: 8)
            }
            if !migrated.contains(where: { $0.kind == .screenRuler }) {
                migrated.insert(OrbAction(id: "screenRuler", title: "Ruler", systemImage: "ruler", isEnabled: true, kind: .screenRuler), at: 9)
            }
            if !migrated.contains(where: { $0.kind == .decisionMaker }) {
                migrated.insert(OrbAction(id: "decisionMaker", title: "Decide", systemImage: "dice", isEnabled: true, kind: .decisionMaker), at: 10)
            }
            if !migrated.contains(where: { $0.kind == .imageConverter }) {
                migrated.insert(OrbAction(id: "imageConverter", title: "Convert", systemImage: "photo.badge.checkmark", isEnabled: true, kind: .imageConverter), at: 11)
            }
            if !migrated.contains(where: { $0.kind == .textStats }) {
                migrated.insert(OrbAction(id: "textStats", title: "Text Stats", systemImage: "textformat.abc", isEnabled: true, kind: .textStats), at: 12)
            }
            if !migrated.contains(where: { $0.kind == .volumeControl }) {
                migrated.append(OrbAction(id: "volume", title: "Volume", systemImage: "speaker.wave.2.fill", isEnabled: true, kind: .volumeControl))
            }
            migrated.removeAll { $0.kind.rawValue == "volumeUp" || $0.kind.rawValue == "volumeDown" }
            migrated.removeAll { $0.kind.rawValue == "mirror" }
            migrated.removeAll { $0.kind.rawValue == "voiceMemo" }
            actions = migrated.isEmpty ? OrbAction.default : migrated
        } else {
            actions = OrbAction.default
        }
    }

    var enabledActions: [OrbAction] {
        actions.filter { $0.isEnabled && $0.kind != .goHome }
    }

    func move(from offsets: IndexSet, to destination: Int) {
        actions.move(fromOffsets: offsets, toOffset: destination)
    }

    func toggleEnabled(_ action: OrbAction) {
        if let idx = actions.firstIndex(of: action) {
            actions[idx].isEnabled.toggle()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(actions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
