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
        // Direct fallback path (no Shortcuts dependency).
        // Requires Accessibility permission.
        _ = runAppleScript("""
        tell application "System Events" to launch
        delay 0.15
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
        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
            let success = process.terminationStatus == 0
            if !success {
                let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                if let err = String(data: data, encoding: .utf8), !err.isEmpty {
                    NSLog("SystemActionManager command error (\(launchPath)): \(err)")
                }
            }
            return success
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
