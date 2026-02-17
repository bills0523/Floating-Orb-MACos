import SwiftUI

struct ScreenRulerView: View {
    @State private var isVisible = true
    @State private var origin = CGPoint(x: 40, y: 36)
    @State private var size = CGSize(width: 170, height: 90)
    private let minSize: CGFloat = 40
    private let maxWidth: CGFloat = 280
    private let maxHeight: CGFloat = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Button(isVisible ? "Hide Overlay" : "Show Overlay") {
                    isVisible.toggle()
                }
                .buttonStyle(.borderedProminent)

                Button("Reset Size") {
                    size = CGSize(width: 170, height: 90)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                Text("W")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Slider(value: widthBinding, in: minSize...maxWidth, step: 1)
                Stepper("\(Int(size.width))", value: widthStepperBinding, in: Int(minSize)...Int(maxWidth))
                    .frame(width: 86)
            }

            HStack(spacing: 10) {
                Text("H")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Slider(value: heightBinding, in: minSize...maxHeight, step: 1)
                Stepper("\(Int(size.height))", value: heightStepperBinding, in: Int(minSize)...Int(maxHeight))
                    .frame(width: 86)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial.opacity(0.35))

                if isVisible {
                    RulerOverlay(
                        origin: $origin,
                        size: $size,
                        minSize: minSize,
                        maxWidth: maxWidth,
                        maxHeight: maxHeight
                    )
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var widthBinding: Binding<Double> {
        Binding(
            get: { size.width },
            set: { size.width = min(max($0, minSize), maxWidth) }
        )
    }

    private var heightBinding: Binding<Double> {
        Binding(
            get: { size.height },
            set: { size.height = min(max($0, minSize), maxHeight) }
        )
    }

    private var widthStepperBinding: Binding<Int> {
        Binding(
            get: { Int(size.width) },
            set: { size.width = CGFloat(min(max($0, Int(minSize)), Int(maxWidth))) }
        )
    }

    private var heightStepperBinding: Binding<Int> {
        Binding(
            get: { Int(size.height) },
            set: { size.height = CGFloat(min(max($0, Int(minSize)), Int(maxHeight))) }
        )
    }
}

private struct RulerOverlay: View {
    @Binding var origin: CGPoint
    @Binding var size: CGSize
    let minSize: CGFloat
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    @State private var moveStartOrigin: CGPoint?
    @State private var resizeStartOrigin: CGPoint?
    @State private var resizeStartSize: CGSize?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.accentColor.opacity(0.18))
                .overlay(
                    Rectangle()
                        .stroke(Color.accentColor, lineWidth: 1.5)
                )
                .overlay(
                    Text("\(Int(size.width)) x \(Int(size.height)) px")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .padding(6)
                        .background(.ultraThinMaterial.opacity(0.9))
                        .clipShape(Capsule())
                )
                .frame(width: size.width, height: size.height)
                .offset(x: origin.x, y: origin.y)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if moveStartOrigin == nil {
                                moveStartOrigin = origin
                            }
                            guard let start = moveStartOrigin else { return }
                            origin = CGPoint(
                                x: start.x + value.translation.width,
                                y: start.y + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            moveStartOrigin = nil
                        }
                )

            cornerHandle(x: origin.x - 8, y: origin.y - 8, dx: -1, dy: -1)
            cornerHandle(x: origin.x + size.width - 8, y: origin.y - 8, dx: 1, dy: -1)
            cornerHandle(x: origin.x - 8, y: origin.y + size.height - 8, dx: -1, dy: 1)
            cornerHandle(x: origin.x + size.width - 8, y: origin.y + size.height - 8, dx: 1, dy: 1)
        }
    }

    private func cornerHandle(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat) -> some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: 16, height: 16)
            .offset(x: x, y: y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if resizeStartOrigin == nil {
                            resizeStartOrigin = origin
                            resizeStartSize = size
                        }
                        guard let startOrigin = resizeStartOrigin, let startSize = resizeStartSize else { return }
                        if dx < 0 {
                            let newWidth = min(maxWidth, max(minSize, startSize.width - value.translation.width))
                            origin.x = startOrigin.x + (startSize.width - newWidth)
                            size.width = newWidth
                        } else {
                            size.width = min(maxWidth, max(minSize, startSize.width + value.translation.width))
                        }
                        if dy < 0 {
                            let newHeight = min(maxHeight, max(minSize, startSize.height - value.translation.height))
                            origin.y = startOrigin.y + (startSize.height - newHeight)
                            size.height = newHeight
                        } else {
                            size.height = min(maxHeight, max(minSize, startSize.height + value.translation.height))
                        }
                    }
                    .onEnded { _ in
                        resizeStartOrigin = nil
                        resizeStartSize = nil
                    }
            )
    }
}
