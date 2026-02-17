import SwiftUI

struct DateUtilityView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case difference = "Difference"
        case add = "Add"

        var id: String { rawValue }
    }

    @State private var mode: Mode = .difference
    @State private var selectedDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var daysToAdd = 45

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .difference {
                differenceContent
            } else {
                addContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var differenceContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            DatePicker(
                "Future Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.field)

            Text(differenceText)
                .font(.system(size: 13, weight: .semibold))
        }
    }

    private var addContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Stepper(value: $daysToAdd, in: 0...10000) {
                Text("Days to add: \(daysToAdd)")
                    .font(.system(size: 13, weight: .semibold))
            }

            Text(resultDateText)
                .font(.system(size: 13, weight: .semibold))
        }
    }

    private var differenceText: String {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let targetStart = calendar.startOfDay(for: selectedDate)
        let days = calendar.dateComponents([.day], from: todayStart, to: targetStart).day ?? 0
        return "\(days) day\(days == 1 ? "" : "s") left"
    }

    private var resultDateText: String {
        guard let target = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date()) else {
            return "Date unavailable"
        }
        let formatted = target.formatted(date: .long, time: .omitted)
        return formatted
    }
}
