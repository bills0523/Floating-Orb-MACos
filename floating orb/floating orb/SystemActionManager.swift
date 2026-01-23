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

    func openFinder() {
        runAppleScript("""
        tell application "Finder"
            if (count of windows) is 0 then
                make new Finder window to home
            end if
            activate
        end tell
        """)
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

    func volumeUp(step: Int = 6) {
        runAppleScript("""
        set ovol to output volume of (get volume settings)
        if ovol > (100 - \(step)) then
            set volume output volume 100
        else
            set volume output volume (ovol + \(step))
        end if
        """)
    }

    func volumeDown(step: Int = 6) {
        runAppleScript("""
        set ovol to output volume of (get volume settings)
        if ovol < \(step) then
            set volume output volume 0
        else
            set volume output volume (ovol - \(step))
        end if
        """)
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
        guard let scriptObject = NSAppleScript(source: script) else {
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
