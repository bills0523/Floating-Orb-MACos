import Foundation
import AppKit

extension Notification.Name {
    static let floatingOrbToast = Notification.Name("floatingOrbToast")
}

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
        postToast("Opened Finder")
    }

    func runCustomCommand() {
        if runShell("/usr/bin/open", arguments: ["-a", "Terminal"]) {
            postToast("Opened Terminal")
        } else {
            postToast("Failed to open Terminal")
        }
    }

    func toggleSystemAppearance() {
        let script = "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"
        guard let appleScript = NSAppleScript(source: script) else {
            postToast("Failed to build appearance script")
            return
        }

        var errorInfo: NSDictionary?
        _ = appleScript.executeAndReturnError(&errorInfo)
        if errorInfo == nil {
            postToast("System appearance toggled")
        } else {
            postToast("Appearance toggle failed. Grant Automation access.")
            NSLog("SystemActionManager appearance script error: \(String(describing: errorInfo))")
        }
    }

    func volumeUp(step: Int = 6) {
        adjustVolume(deltaPercent: max(1, step))
    }

    func volumeDown(step: Int = 6) {
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

        if let current = currentVolumePercent() {
            postToast("Current volume: \(current)%")
        } else {
            postToast("Volume changed")
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

    private func postToast(_ message: String) {
        NotificationCenter.default.post(name: .floatingOrbToast, object: nil, userInfo: ["message": message])
    }

    private func runShellCapture(_ launchPath: String, arguments: [String]) -> (success: Bool, output: String, error: String) {
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
            return (success, out, err)
        } catch {
            NSLog("SystemActionManager shell capture error: \(error)")
            return (false, "", "\(error)")
        }
    }

}
