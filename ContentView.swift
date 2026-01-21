import SwiftUI

struct ContentView: View {
    @State private var isExpanded = false
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 220, height: 180)
                    .shadow(radius: 8)
                    .overlay(menuButtons.padding())
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
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
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.1)) {
                isExpanded.toggle()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .floatingPanelSnap()
    }

    private var menuButtons: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            Button {
                SystemActionManager.shared.goHome()
            } label: {
                label(systemName: "rectangle.3.offgrid", title: "Desktop")
            }

            Button {
                SystemActionManager.shared.toggleDoNotDisturb()
            } label: {
                label(systemName: "moon.zzz", title: "Focus")
            }

            Button {
                SystemActionManager.shared.runCustomCommand()
            } label: {
                label(systemName: "terminal", title: "Command")
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded = false
                }
            } label: {
                label(systemName: "xmark.circle", title: "Close")
            }
        }
    }

    private func label(systemName: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .background(.thinMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    ContentView()
}
