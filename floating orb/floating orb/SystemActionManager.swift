import Foundation
import AppKit
import ApplicationServices

extension Notification.Name {
    static let floatingOrbToast = Notification.Name("floatingOrbToast")
    static let floatingOrbShowDNDPermissionGuide = Notification.Name("floatingOrbShowDNDPermissionGuide")
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

    func toggleDoNotDisturb() {
        guard ensureDNDPermission(prompt: true) else {
            NotificationCenter.default.post(name: .floatingOrbShowDNDPermissionGuide, object: nil)
            return
        }

        // Open Focus first, then toggle Do Not Disturb inside Focus panel.
        let result = runAppleScriptCapture("""
        tell application "System Events"
            tell process "ControlCenter"
                set frontmost to true
                click (first menu bar item of menu bar 1 whose description contains "Control Center" or description contains "control center")
                delay 0.3

                set didToggle to false
                set uiItems to {}
                try
                    set uiItems to entire contents of window 1
                end try

                -- Step 1: open Focus module in Control Center.
                repeat with e in uiItems
                    set n to ""
                    set d to ""
                    try
                        set n to (name of e) as text
                    end try
                    try
                        set d to (description of e) as text
                    end try
                    if n contains "Focus" or d contains "Focus" then
                        try
                            perform action "AXPress" of e
                        on error
                            try
                                click e
                            end try
                        end try
                        exit repeat
                    end if
                end repeat

                delay 0.25
                try
                    set uiItems to entire contents of window 1
                end try

                -- Step 2: toggle Do Not Disturb item inside Focus.
                repeat with e in uiItems
                    set n to ""
                    set d to ""
                    try
                        set n to (name of e) as text
                    end try
                    try
                        set d to (description of e) as text
                    end try
                    if n contains "Do Not Disturb" or d contains "Do Not Disturb" or n contains "DND" or d contains "DND" then
                        try
                            perform action "AXPress" of e
                        on error
                            try
                                click e
                            end try
                        end try
                        set didToggle to true
                        exit repeat
                    end if
                end repeat

                key code 53
                return didToggle
            end tell
        end tell
        """)

        if result.success && result.output.lowercased().contains("true") {
            postToast("Do Not Disturb toggled")
        } else {
            if !ensureDNDPermission(prompt: false) {
                postToast("DND blocked: allow Accessibility for Floating Orb.")
                openAccessibilitySettings()
                NotificationCenter.default.post(name: .floatingOrbShowDNDPermissionGuide, object: nil)
            } else {
                postToast("Could not find the Focus/Do Not Disturb toggle in Control Center.")
            }
        }
    }

    func triggerDNDPermissionSetup() {
        if ensureDNDPermission(prompt: true) {
            postToast("DND permission ready. Retry DND.")
        } else {
            postToast("Grant Accessibility, then tap Retry DND.")
            openAccessibilitySettings()
        }
    }

    func retryDNDToggle() {
        toggleDoNotDisturb()
    }

    func runCustomCommand() {
        if runShell("/usr/bin/open", arguments: ["-a", "Terminal"]) {
            postToast("Opened Terminal")
        } else {
            postToast("Failed to open Terminal")
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

    private func runAppleScriptCapture(_ script: String) -> (success: Bool, output: String, error: String) {
        runShellCapture("/usr/bin/osascript", arguments: ["-e", script])
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

    func accessibilityPermissionGranted() -> Bool {
        ensureDNDPermission(prompt: false)
    }

    private func ensureDNDPermission(prompt: Bool) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted { return false }

        // Verify System Events UI scripting actually works (not just trust bit).
        let probe = runAppleScriptCapture("""
        tell application "System Events"
            return UI elements enabled
        end tell
        """)
        return probe.success && probe.output.lowercased().contains("true")
    }

    func openAccessibilitySettings() {
        _ = runShell("/usr/bin/open", arguments: ["x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"])
    }
}
