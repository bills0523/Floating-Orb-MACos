import Foundation
import Combine
import SwiftUI // for move(fromOffsets:toOffset:)

struct OrbAction: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case goHome
        case focus
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
        OrbAction(id: "desktop", title: "Desktop", systemImage: "rectangle.3.offgrid", isEnabled: true, kind: .goHome),
        OrbAction(id: "focus", title: "Focus", systemImage: "moon.zzz", isEnabled: true, kind: .focus),
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
            actions = decoded
        } else {
            actions = OrbAction.default
        }
    }

    var enabledActions: [OrbAction] {
        actions.filter { $0.isEnabled }
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
