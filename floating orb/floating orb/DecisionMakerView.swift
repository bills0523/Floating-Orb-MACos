import SwiftUI
import AppKit

struct DecisionMakerView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case coin = "Coin Flip"
        case dice = "Dice Roll"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .coin
    @State private var coinResult = "Heads"
    @State private var diceResult = 1
    @State private var spin = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .coin {
                VStack(spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 52))
                        .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
                    Text(coinResult)
                        .font(.system(size: 16, weight: .semibold))
                    Button("Flip") { flipCoin() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 10) {
                    Text("\(diceResult)")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                    Button("Roll") { rollDice() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func flipCoin() {
        withAnimation(.easeInOut(duration: 0.5)) {
            spin += 720
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            coinResult = Bool.random() ? "Heads" : "Tails"
            NSSound.beep()
        }
    }

    private func rollDice() {
        diceResult = Int.random(in: 1...6)
        NSSound.beep()
    }
}
