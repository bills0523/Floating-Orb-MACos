//
//  floating_orbApp.swift
//  floating orb
//
//  Created by Biushang on 1/21/26.
//

import SwiftUI
import AppKit
import ApplicationServices

@main
struct FloatingOrbApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // Panel is managed in AppDelegate; no visible scenes needed.
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel<AnyView>?
    private let actionStore = ActionStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestAccessibility()

        let content = AnyView(ContentView()
            .environmentObject(actionStore))
        panel = FloatingPanel(content: content)
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func requestAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            NSLog("Accessibility permission not granted yet; prompting user.")
        }
    }
}
