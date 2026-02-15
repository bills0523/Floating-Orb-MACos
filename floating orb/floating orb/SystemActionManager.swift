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
        // Try toggling Focus from Control Center first (no custom shortcut needed).
        if runAppleScript("""
        tell application "System Events"
            tell process "ControlCenter"
                set frontmost to true
                click (first menu bar item of menu bar 1 whose description contains "Control Center")
                delay 0.2
                try
                    click (first checkbox of first window whose name contains "Control Center")
                on error
                    click (first button of first window whose name contains "Control Center" whose name contains "Focus")
                end try
                key code 53
            end tell
        end tell
        """) {
            return
        }

        // Final fallback: keyboard shortcut path if configured by user.
        _ = runAppleScript("""
        tell application "System Events" to key code 107 using {control down, shift down}
        """)
    }

    func runCustomCommand() {
        _ = runShell("/usr/bin/open", arguments: ["-a", "Terminal"])
    }

    func volumeUp(step: Int = 1) {
        pressVolumeKey(keyCode: 72, times: max(1, step))
    }

    func volumeDown(step: Int = 1) {
        pressVolumeKey(keyCode: 73, times: max(1, step))
    }

    private func pressVolumeKey(keyCode: Int, times: Int) {
        _ = runAppleScript("""
        tell application "System Events"
            repeat \(times) times
                key code \(keyCode)
                delay 0.02
            end repeat
        end tell
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
