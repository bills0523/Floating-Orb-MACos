import SwiftUI

struct ContentView: View {
    @State private var isExpanded = false
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
        .highPriorityGesture(
            DragGesture(minimumDistance: 1)
                .onChanged { _ in }
        )
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
                actionButton(systemName: "rectangle.3.offgrid", title: "Desktop") {
                    SystemActionManager.shared.goHome()
                }
                actionButton(systemName: "moon.zzz", title: "Focus") {
                    SystemActionManager.shared.toggleDoNotDisturb()
                }
                actionButton(systemName: "terminal", title: "Command") {
                    SystemActionManager.shared.runCustomCommand()
                }
                actionButton(systemName: "folder", title: "Finder") {
                    SystemActionManager.shared.openFinder()
                }
                actionButton(systemName: "speaker.wave.2", title: "Vol Up") {
                    SystemActionManager.shared.volumeUp()
                }
                actionButton(systemName: "speaker.wave.1", title: "Vol Down") {
                    SystemActionManager.shared.volumeDown()
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
    }

    private var header: some View {
        HStack {
            Text("Floating Orb")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Text("v1.0")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
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
}

#Preview {
    ContentView()
}
