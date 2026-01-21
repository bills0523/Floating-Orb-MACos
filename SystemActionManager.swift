import Foundation
import AppKit

/// Runs lightweight system actions and shell commands from SwiftUI.
final class SystemActionManager {
    static let shared = SystemActionManager()
    private init() {}

    func goHome() {
        // Show Desktop (F11) via AppleScript so we don't depend on private APIs.
        runAppleScript("tell application \"System Events\" to key code 103")
    }

    func toggleDoNotDisturb() {
        // Expect a Shortcuts shortcut named "Toggle Focus" or fallback to the Control+Shift+F15 shortcut.
        if !runShell("/usr/bin/shortcuts", arguments: ["run", "Toggle Focus"]) {
            runAppleScript("tell application \"System Events\" to key code 107 using {control down, shift down}")
        }
    }

    func runCustomCommand() {
        _ = runShell("/bin/zsh", arguments: ["-c", "echo 'Custom command placeholder executed'"])
    }

    @discardableResult
    private func runShell(_ launchPath: String, arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = nil
        process.standardError = nil

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            NSLog("SystemActionManager shell error: \(error)")
            return false
        }
    }

    private func runAppleScript(_ script: String) {
        guard let data = script.data(using: .utf8),
              let scriptObject = NSAppleScript(data: data) else {
            NSLog("SystemActionManager could not build AppleScript")
            return
        }
        var errorDict: NSDictionary?
        scriptObject.executeAndReturnError(&errorDict)
        if let errorDict {
            NSLog("SystemActionManager AppleScript error: \(errorDict)")
        }
    }
}
