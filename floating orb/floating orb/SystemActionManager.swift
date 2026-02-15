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
        // Toggle Do Not Disturb via Control Center UI scripting.
        // This requires Accessibility permission and may vary slightly by macOS version.
        _ = runAppleScript("""
        tell application "System Events"
            tell process "ControlCenter"
                set frontmost to true
                click (first menu bar item of menu bar 1 whose description contains "Control Center")
                delay 0.25
                try
                    click (first button of first window whose name contains "Control Center" whose name contains "Focus")
                on error
                    click (first button of first window whose name contains "Control Center" whose description contains "Focus")
                end try
                delay 0.15
                try
                    click (first checkbox of first window whose title contains "Focus" whose description contains "Do Not Disturb")
                on error
                    try
                        click (first button of first window whose title contains "Focus" whose name contains "Do Not Disturb")
                    on error
                        click (first button of first window whose name contains "Do Not Disturb")
                    end try
                end try
                key code 53
            end tell
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
        set currentVolume to output volume of (get volume settings)
        set targetVolume to currentVolume + \(deltaPercent)
        if targetVolume > 100 then set targetVolume to 100
        if targetVolume < 0 then set targetVolume to 0
        set volume output volume targetVolume
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
