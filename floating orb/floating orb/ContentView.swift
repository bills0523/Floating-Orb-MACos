import SwiftUI

struct ContentView: View {
    @EnvironmentObject var actionStore: ActionStore
    @State private var isExpanded = false
    @State private var showingEditor = false
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
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.1)) {
                isExpanded.toggle()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .floatingPanelDraggable()
    }

    private var contentPanel: some View {
        VStack(spacing: 16) {
            header
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(actionStore.enabledActions) { action in
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
        .padding(20)
        .sheet(isPresented: $showingEditor) { editorSheet }
    }

    private var header: some View {
        HStack {
            Text("Floating Orb")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Button {
                showingEditor = true
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

    private var editorSheet: some View {
        NavigationView {
            List {
                ForEach($actionStore.actions) { $action in
                    HStack {
                        Toggle(isOn: $action.isEnabled) {
                            HStack(spacing: 10) {
                                Image(systemName: action.systemImage)
                                Text(action.title)
                            }
                        }
                        .toggleStyle(.switch)
                        Spacer()
                        moveButtons(for: action)
                    }
                }
            }
            .navigationTitle("Actions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { showingEditor = false }
                }
            }
            .frame(minWidth: 320, minHeight: 420)
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
}

#Preview {
    ContentView()
}
