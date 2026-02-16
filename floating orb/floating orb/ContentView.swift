import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var actionStore: ActionStore
    @State private var isExpanded = false
    @State private var showingEditor = false
    @State private var window: NSWindow?
    @State private var toastMessage: String?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 320, height: 400)
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
            } else {
                header
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(displayedActions) { action in
                        actionButton(systemName: action.systemImage, title: action.title) {
                            perform(action)
                        }
                    }
                    actionButton(systemName: "xmark.circle", title: "Close") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isExpanded = false
                        }
                    }
                }
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
            .frame(maxWidth: .infinity, minHeight: 74)
            .padding(10)
            .background(.thinMaterial.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func perform(_ action: OrbAction) {
        let manager = SystemActionManager.shared
        switch action.kind {
        case .goHome: manager.goHome()
        case .focus: manager.toggleDoNotDisturb()
        case .command: manager.runCustomCommand()
        case .finder: manager.openFinder()
        case .volumeUp: manager.volumeUp()
        case .volumeDown: manager.volumeDown()
        }
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
        let size = expanded ? NSSize(width: 340, height: 420) : NSSize(width: 90, height: 90)
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

#Preview {
    ContentView()
}
