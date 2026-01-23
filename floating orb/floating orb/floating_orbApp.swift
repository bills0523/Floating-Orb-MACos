//
//  floating_orbApp.swift
//  floating orb
//
//  Created by Biushang on 1/21/26.
//

import SwiftUI
import AppKit

@main
struct FloatingOrbApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // Panel is managed in AppDelegate; no visible scenes needed.
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel<ContentView>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let content = ContentView()
        panel = FloatingPanel(content: content)
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
