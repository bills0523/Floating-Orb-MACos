import Foundation
import AppKit
import UserNotifications

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
        // This requires Accessibility permission and UI labels may vary by macOS/localization.
        let toggled = runAppleScript("""
        tell application "System Events"
            tell process "ControlCenter"
                set frontmost to true
                click (first menu bar item of menu bar 1 whose description contains "Control Center" or description contains "control center")
                delay 0.25
                set toggled to false
                try
                    set dndControl to first checkbox of (entire contents of window 1) whose (name contains "Do Not Disturb" or description contains "Do Not Disturb")
                    click dndControl
                    set toggled to true
                end try

                if toggled is false then
                    try
                        set focusControl to first button of (entire contents of window 1) whose (name contains "Focus" or description contains "Focus")
                        click focusControl
                        delay 0.2
                        set dndControl to first checkbox of (entire contents of window 1) whose (name contains "Do Not Disturb" or description contains "Do Not Disturb")
                        click dndControl
                        set toggled to true
                    end try
                end try

                key code 53
            end tell
        end tell
        """)
        notify(title: "Floating Orb", body: toggled ? "Do Not Disturb toggle attempted." : "Could not locate Do Not Disturb control.")
    }

    func runCustomCommand() {
        _ = runShell("/usr/bin/open", arguments: ["-a", "Terminal"])
    }

    func volumeUp(step: Int = 6) {
        adjustVolume(deltaPercent: max(1, step))
    }

    func volumeDown(step: Int = 6) {
        adjustVolume(deltaPercent: -max(1, step))
    }

    private func adjustVolume(deltaPercent: Int) {
        let didSet = runAppleScript("""
        set currentVolume to output volume of (get volume settings)
        set targetVolume to currentVolume + \(deltaPercent)
        if targetVolume > 100 then set targetVolume to 100
        if targetVolume < 0 then set targetVolume to 0
        set volume output volume targetVolume
        """)
        if !didSet {
            _ = runAppleScript("""
            tell application "System Events"
                key code \(deltaPercent > 0 ? 72 : 73)
            end tell
            """)
        }
        let current = currentVolumePercent()
        if let current {
            notify(title: "Floating Orb", body: "Current volume: \(current)%")
        } else {
            notify(title: "Floating Orb", body: "Volume changed.")
        }
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

    private func currentVolumePercent() -> Int? {
        let result = runShellCapture("/usr/bin/osascript", arguments: ["-e", "output volume of (get volume settings)"])
        guard result.success else { return nil }
        let trimmed = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(trimmed)
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func runShellCapture(_ launchPath: String, arguments: [String]) -> (success: Bool, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
            let out = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let err = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let success = process.terminationStatus == 0
            if !success && !err.isEmpty {
                NSLog("SystemActionManager command error (\(launchPath)): \(err)")
            }
            return (success, out)
        } catch {
            NSLog("SystemActionManager shell capture error: \(error)")
            return (false, "")
        }
    }
}
