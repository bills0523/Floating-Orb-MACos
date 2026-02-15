import Foundation
import AppKit
import CoreAudio

/// Runs lightweight system actions and shell commands from SwiftUI.
final class SystemActionManager {
    static let shared = SystemActionManager()
    private init() {}

    func goHome() {
        // "Return to desktop" implemented as opening desktop in Finder (reliable).
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? NSHomeDirectory()
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: desktop)
    }

    func openFinder() {
        // Use NSWorkspace to avoid AppleScript permissions.
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: NSHomeDirectory())
    }

    func toggleDoNotDisturb() {
        // Preferred path: user-created Shortcuts action named "Toggle Focus".
        if runShell("/usr/bin/shortcuts", arguments: ["run", "Toggle Focus"]) {
            return
        }
        // Fallback: open Focus settings so user can toggle quickly.
        _ = runShell("/usr/bin/open", arguments: ["x-apple.systempreferences:com.apple.preference.notifications"])
    }

    func runCustomCommand() {
        // Visible default command so users can confirm button wiring works.
        _ = runShell("/usr/bin/open", arguments: ["-a", "Terminal"])
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
            // Fallback for devices that do not expose CoreAudio scalar control.
            runVolumeAppleScript(deltaPercent: Int(delta * 100))
            return
        }

        let volume = currentVolume(deviceID: deviceID)
        let newVolume = max(0.0, min(1.0, volume + delta))
        if !setDeviceVolume(deviceID: deviceID, value: newVolume) {
            runVolumeAppleScript(deltaPercent: Int(delta * 100))
        }
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

    private func runVolumeAppleScript(deltaPercent: Int) {
        let script = """
        set ovol to output volume of (get volume settings)
        set nvol to ovol + \(deltaPercent)
        if nvol > 100 then set nvol to 100
        if nvol < 0 then set nvol to 0
        set volume output volume nvol
        """
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
