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
        case volumeUp
        case volumeDown
    }

    var id: String
    var title: String
    var systemImage: String
    var isEnabled: Bool
    var kind: Kind

    static let `default`: [OrbAction] = [
        OrbAction(id: "desktopIcons", title: "Desktop", systemImage: "eye", isEnabled: true, kind: .desktopIcons),
        OrbAction(id: "appearance", title: "Theme", systemImage: "sun.max.fill", isEnabled: true, kind: .appearance),
        OrbAction(id: "command", title: "Command", systemImage: "terminal", isEnabled: true, kind: .command),
        OrbAction(id: "finder", title: "Finder", systemImage: "folder", isEnabled: true, kind: .finder),
        OrbAction(id: "volUp", title: "Vol Up", systemImage: "speaker.wave.2", isEnabled: true, kind: .volumeUp),
        OrbAction(id: "volDown", title: "Vol Down", systemImage: "speaker.wave.1", isEnabled: true, kind: .volumeDown)
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
