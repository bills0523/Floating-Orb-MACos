import SwiftUI
import AppKit

struct ContentView: View {
    enum ToolPage {
        case volume
        case clipboard
        case qrCode
        case latency
        case referenceImage
        case dateUtility
        case quickTimer
        case stickyNote
        case screenRuler
        case decisionMaker
        case imageConverter
        case textStats
    }

    @EnvironmentObject var actionStore: ActionStore
    @State private var isExpanded = false
    @State private var showingEditor = false
    @State private var toolPage: ToolPage?
    @State private var window: NSWindow?
    @State private var toastMessage: String?
    @State private var desktopIconsVisible = SystemActionManager.shared.desktopIconsVisible()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    private let actionViewportHeight: CGFloat = 312

    var body: some View {
        ZStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 332, height: 456)
                    .shadow(radius: 12)
                    .overlay(contentPanel)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "circle.grid.hex")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.primary)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(minWidth: 72, minHeight: 72)
        .contentShape(Rectangle())
        .background(WindowCapture(window: $window))
        .overlay(alignment: .top) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.72))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.top, isExpanded ? 8 : -14)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.1)) {
                isExpanded.toggle()
            }
            resizeWindow(expanded: isExpanded)
        }
        .onReceive(NotificationCenter.default.publisher(for: .floatingOrbToast)) { notification in
            guard let message = notification.userInfo?["message"] as? String else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                toastMessage = message
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeIn(duration: 0.2)) {
                    if toastMessage == message {
                        toastMessage = nil
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .floatingPanelDraggable()
    }

    private var contentPanel: some View {
        VStack(spacing: 16) {
            if showingEditor {
                editorPanel
            } else if let toolPage {
                toolPanel(for: toolPage)
            } else {
                header
                ScrollView(.vertical) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayedActions) { action in
                            actionButton(systemName: iconName(for: action), title: actionTitle(for: action)) {
                                perform(action)
                            }
                        }
                        actionButton(systemName: "xmark.circle", title: "Close") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isExpanded = false
                            }
                        }
                    }
                    .padding(.trailing, 2)
                }
                .frame(height: actionViewportHeight)
                Spacer(minLength: 0)
            }
        }
        .padding(20)
    }

    private var header: some View {
        HStack {
            Text("Floating Orb")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingEditor = true
                    toolPage = nil
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
    }

    private func actionButton(systemName: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(10)
            .background(.thinMaterial.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func perform(_ action: OrbAction) {
        let manager = SystemActionManager.shared
        switch action.kind {
        case .goHome: manager.goHome()
        case .desktopIcons:
            let newState = !desktopIconsVisible
            desktopIconsVisible = newState
            manager.toggleDesktopIcons(visible: newState)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                desktopIconsVisible = manager.desktopIconsVisible()
            }
        case .appearance: manager.toggleSystemAppearance()
        case .command: manager.runCustomCommand()
        case .finder: manager.openFinder()
        case .volumeControl: toolPage = .volume
        case .clipboard: toolPage = .clipboard
        case .qrCode: toolPage = .qrCode
        case .latency: toolPage = .latency
        case .referenceImage: toolPage = .referenceImage
        case .dateUtility: toolPage = .dateUtility
        case .quickTimer: toolPage = .quickTimer
        case .stickyNote: toolPage = .stickyNote
        case .screenRuler: toolPage = .screenRuler
        case .decisionMaker: toolPage = .decisionMaker
        case .imageConverter: toolPage = .imageConverter
        case .textStats: toolPage = .textStats
        }
    }

    @ViewBuilder
    private func toolPanel(for page: ToolPage) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(toolTitle(for: page))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("Back") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        toolPage = nil
                    }
                }
                .buttonStyle(.borderless)
            }

            switch page {
            case .volume:
                VolumeControlToolView()
            case .clipboard:
                ClipboardToolView()
            case .qrCode:
                QRCodeGeneratorView()
            case .latency:
                LatencyToolView()
            case .referenceImage:
                FloatingReferenceImageToolView()
            case .dateUtility:
                DateUtilityView()
            case .quickTimer:
                QuickTimerView()
            case .stickyNote:
                StickyNoteView()
            case .screenRuler:
                ScreenRulerView()
            case .decisionMaker:
                DecisionMakerView()
            case .imageConverter:
                ImageConverterView()
            case .textStats:
                ClipboardStatsView()
            }
            Spacer(minLength: 0)
        }
    }

    private func toolTitle(for page: ToolPage) -> String {
        switch page {
        case .volume: return "Volume"
        case .clipboard: return "Clipboard"
        case .qrCode: return "QR Code"
        case .latency: return "Network Latency"
        case .referenceImage: return "Reference Image"
        case .dateUtility: return "Date Utility"
        case .quickTimer: return "Quick Timer"
        case .stickyNote: return "Scratchpad"
        case .screenRuler: return "Screen Ruler"
        case .decisionMaker: return "Decision Maker"
        case .imageConverter: return "Image Converter"
        case .textStats: return "Text Stats"
        }
    }

    private func iconName(for action: OrbAction) -> String {
        if action.kind == .desktopIcons {
            return desktopIconsVisible ? "eye" : "eye.slash"
        }
        return action.systemImage
    }

    private func actionTitle(for action: OrbAction) -> String {
        if action.kind == .desktopIcons {
            return desktopIconsVisible ? "Hide Icons" : "Show Icons"
        }
        return action.title
    }

    private var editorPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Customize Actions")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("Done") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingEditor = false
                    }
                }
                .buttonStyle(.borderless)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach($actionStore.actions) { $action in
                        HStack(spacing: 10) {
                            Toggle(isOn: $action.isEnabled) {
                                HStack(spacing: 10) {
                                    Image(systemName: action.systemImage)
                                    Text(action.title)
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .toggleStyle(.switch)
                            Spacer()
                            moveButtons(for: action)
                        }
                        .padding(8)
                        .background(.thinMaterial.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func moveButtons(for action: OrbAction) -> some View {
        HStack(spacing: 6) {
            Button {
                move(action, offset: -1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)

            Button {
                move(action, offset: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
        }
    }

    private func move(_ action: OrbAction, offset: Int) {
        guard let index = actionStore.actions.firstIndex(of: action) else { return }
        let newIndex = max(0, min(actionStore.actions.count - 1, index + offset))
        if newIndex != index {
            var actions = actionStore.actions
            let item = actions.remove(at: index)
            actions.insert(item, at: newIndex)
            actionStore.actions = actions
        }
    }

    private var displayedActions: [OrbAction] {
        let enabled = actionStore.enabledActions
        return enabled.isEmpty ? OrbAction.default : enabled
    }

    private func resizeWindow(expanded: Bool) {
        guard let window else { return }
        let size = expanded ? NSSize(width: 352, height: 476) : NSSize(width: 90, height: 90)
        window.setContentSize(size)
    }

    private struct WindowCapture: NSViewRepresentable {
        @Binding var window: NSWindow?
        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: .zero)
            DispatchQueue.main.async { self.window = view.window }
            return view
        }
        func updateNSView(_ nsView: NSView, context: Context) {
            DispatchQueue.main.async { self.window = nsView.window }
        }
    }
}

private struct VolumeControlToolView: View {
    @State private var volumePercent: Double = 50
    @State private var didLoad = false
    private let manager = SystemActionManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(Int(volumePercent))%")
                .font(.system(size: 26, weight: .bold, design: .rounded))

            Slider(value: $volumePercent, in: 0...100, step: 1)
                .onChange(of: volumePercent) { _, newValue in
                    guard didLoad else { return }
                    _ = manager.setVolumePercent(Int(newValue))
                }

            HStack(spacing: 8) {
                Button("0%") { setVolume(0) }
                Button("50%") { setVolume(50) }
                Button("100%") { setVolume(100) }
            }
            .buttonStyle(.bordered)
        }
        .onAppear {
            if let current = manager.currentVolumePercent() {
                volumePercent = Double(current)
            }
            didLoad = true
        }
    }

    private func setVolume(_ value: Int) {
        volumePercent = Double(value)
        _ = manager.setVolumePercent(value)
    }
}

private struct ClipboardToolView: View {
    @StateObject private var manager = ClipboardManager()

    var body: some View {
        ClipboardHistoryView(manager: manager)
    }
}

private struct LatencyToolView: View {
    @StateObject private var monitor = LatencyMonitor()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LatencyStatusView(monitor: monitor)
            Button {
                monitor.checkNow()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text(monitor.isChecking ? "Checking..." : "Check Now")
                }
                .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(monitor.isChecking)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if monitor.latencyMs == nil && !monitor.isChecking {
                monitor.checkNow()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ActionStore())
}
