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
        // Run user Shortcuts directly; no settings fallback.
        let candidates = ["Toggle Focus", "Toggle Do Not Disturb", "Turn On Do Not Disturb", "Turn Off Do Not Disturb"]
        for name in candidates {
            if runShell("/usr/bin/shortcuts", arguments: ["run", name]) {
                return
            }
        }
        NSLog("SystemActionManager: no Do Not Disturb shortcut found. Create one in Shortcuts app.")
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
            return
        }

        let volume = currentVolume(deviceID: deviceID)
        let newVolume = max(0.0, min(1.0, volume + delta))
        if !setDeviceVolume(deviceID: deviceID, value: newVolume) {
            NSLog("SystemActionManager: failed to set output volume via CoreAudio")
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
    if let vol = readVolume(deviceID: deviceID, element: kAudioObjectPropertyElementMain) {
        return vol
    }
    let left = readVolume(deviceID: deviceID, element: 1)
    let right = readVolume(deviceID: deviceID, element: 2)
    if let left, let right {
        return (left + right) / 2.0
    }
    if let left {
        return left
    }
    if let right {
        return right
    }
    return 0
}

private func setDeviceVolume(deviceID: AudioObjectID, value: Float) -> Bool {
    if writeVolume(deviceID: deviceID, element: kAudioObjectPropertyElementMain, value: value) {
        return true
    }
    var wroteAny = false
    if writeVolume(deviceID: deviceID, element: 1, value: value) {
        wroteAny = true
    }
    if writeVolume(deviceID: deviceID, element: 2, value: value) {
        wroteAny = true
    }
    return wroteAny
}

private func readVolume(deviceID: AudioObjectID, element: UInt32) -> Float? {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: element
    )
    if !AudioObjectHasProperty(deviceID, &propertyAddress) {
        return nil
    }
    var volume = Float32(0)
    var size = UInt32(MemoryLayout<Float32>.size)
    let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &volume)
    return status == noErr ? Float(volume) : nil
}

private func writeVolume(deviceID: AudioObjectID, element: UInt32, value: Float) -> Bool {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: element
    )
    if !AudioObjectHasProperty(deviceID, &propertyAddress) {
        return false
    }
    var vol = Float32(value)
    let size = UInt32(MemoryLayout<Float32>.size)
    let status = AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, size, &vol)
    return status == noErr
}
