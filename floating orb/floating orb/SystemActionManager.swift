import Foundation
import AppKit
import CoreAudio

/// Runs lightweight system actions and shell commands from SwiftUI.
final class SystemActionManager {
    static let shared = SystemActionManager()
    private init() {}

    func goHome() {
        // Show Desktop (F11). Requires Accessibility permission.
        runAppleScript("""
        tell application "System Events" to key code 103
        """)
    }

    func openFinder() {
        // Use NSWorkspace to avoid AppleScript permissions.
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: NSHomeDirectory())
    }

    func toggleDoNotDisturb() {
        // Expect a Shortcuts shortcut named "Toggle Focus" or fallback to the Control+Shift+F15 shortcut.
        if !runShell("/usr/bin/shortcuts", arguments: ["run", "Toggle Focus"]) {
            runAppleScript("""
            tell application "System Events" to key code 107 using {control down, shift down}
            """)
        }
    }

    func runCustomCommand() {
        _ = runShell("/bin/zsh", arguments: ["-c", "echo 'Custom command placeholder executed'"])
    }

    func volumeUp(step: Int = 1) {
        adjustVolume(delta: Float(step) / 100.0)
    }

    func volumeDown(step: Int = 1) {
        adjustVolume(delta: -Float(step) / 100.0)
    }

    private func adjustVolume(delta: Float) {
        guard let deviceID = defaultOutputDevice() else {
            NSLog("SystemActionManager: no output device")
            return
        }

        let volume = currentVolume(deviceID: deviceID)
        let newVolume = max(0.0, min(1.0, volume + delta))
        _ = setDeviceVolume(deviceID: deviceID, value: newVolume)
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
        _ = runShell("/usr/bin/osascript", arguments: ["-e", script])
    }
}

// MARK: - CoreAudio helpers

private func defaultOutputDevice() -> AudioObjectID? {
    var deviceID = AudioObjectID(bitPattern: 0)
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                            &propertyAddress,
                                            0,
                                            nil,
                                            &size,
                                            &deviceID)
    return (status == noErr && deviceID != AudioObjectID(kAudioObjectUnknown)) ? deviceID : nil
}

private func currentVolume(deviceID: AudioObjectID) -> Float {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    var volume = Float32(0)
    var size = UInt32(MemoryLayout<Float32>.size)
    let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &volume)
    if status != noErr {
        return 0
    }
    return Float(volume)
}

private func setDeviceVolume(deviceID: AudioObjectID, value: Float) -> Bool {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    var vol = Float32(value)
    let size = UInt32(MemoryLayout<Float32>.size)
    let status = AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, size, &vol)
    return status == noErr
}
