import SwiftUI
import UserNotifications
import AppKit

struct QuickTimerView: View {
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(timeText)
                .font(.system(size: 28, weight: .bold, design: .monospaced))

            HStack(spacing: 8) {
                presetButton(title: "5 Min", seconds: 5 * 60)
                presetButton(title: "15 Min", seconds: 15 * 60)
                presetButton(title: "25 Min", seconds: 25 * 60)
            }

            Button("Cancel") {
                cancelTimer()
            }
            .buttonStyle(.bordered)
            .disabled(remainingSeconds == 0)
        }
        .onDisappear {
            cancelTimer()
        }
    }

    private var timeText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func presetButton(title: String, seconds: Int) -> some View {
        Button(title) {
            startTimer(seconds: seconds)
        }
        .buttonStyle(.borderedProminent)
    }

    private func startTimer(seconds: Int) {
        cancelTimer()
        remainingSeconds = seconds
        requestNotificationPermissionIfNeeded()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
            if remainingSeconds == 0 {
                timer?.invalidate()
                timer = nil
                NSSound.beep()
                sendCompletionNotification()
            }
        }
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
        remainingSeconds = 0
    }

    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Quick Timer"
        content.body = "Timer finished."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
