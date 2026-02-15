import Foundation
import AppKit

/// Runs lightweight system actions and shell commands from SwiftUI.
final class SystemActionManager {
    static let shared = SystemActionManager()
    private init() {}

    func goHome() {
        // Deprecated action slot; currently hidden from UI.
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? NSHomeDirectory()
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: desktop)
    }

    func openFinder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: NSHomeDirectory())
    }

    func toggleDoNotDisturb() {
        // First try user shortcuts by common names.
        let candidates = [
            "Toggle Focus",
            "Toggle Do Not Disturb",
            "Turn On Do Not Disturb",
            "Turn Off Do Not Disturb"
        ]

        for name in candidates where runShell("/usr/bin/shortcuts", arguments: ["run", name]) {
            return
        }

        // Fallback: trigger the system shortcut key path via System Events.
        // This requires Accessibility permission and depends on user shortcut mapping.
        _ = runAppleScript("""
        tell application "System Events"
            key code 107 using {control down, shift down}
        end tell
        """)
    }

    func runCustomCommand() {
        _ = runShell("/usr/bin/open", arguments: ["-a", "Terminal"])
    }

    func volumeUp(step: Int = 1) {
        adjustVolume(deltaPercent: max(1, step))
    }

    func volumeDown(step: Int = 1) {
        adjustVolume(deltaPercent: -max(1, step))
    }

    private func adjustVolume(deltaPercent: Int) {
        _ = runAppleScript("""
        set ovol to output volume of (get volume settings)
        set nvol to ovol + \(deltaPercent)
        if nvol > 100 then set nvol to 100
        if nvol < 0 then set nvol to 0
        set volume output volume nvol
        """)
    }

    @discardableResult
    private func runShell(_ launchPath: String, arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            NSLog("SystemActionManager shell error: \(error)")
            return false
        }
    }

    @discardableResult
    private func runAppleScript(_ script: String) -> Bool {
        runShell("/usr/bin/osascript", arguments: ["-e", script])
    }
}
