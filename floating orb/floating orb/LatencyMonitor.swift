import Foundation
import SwiftUI

final class LatencyMonitor: ObservableObject {
    @Published var latencyMs: Int?

    private var timer: Timer?
    private let session = URLSession(configuration: .ephemeral)
    private let url = URL(string: "https://captive.apple.com/hotspot-detect.html")!

    init() {
        ping()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func ping() {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0
        let start = Date()

        session.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let http = response as? HTTPURLResponse,
                      (200...399).contains(http.statusCode) else {
                    self?.latencyMs = nil
                    return
                }
                self?.latencyMs = Int(Date().timeIntervalSince(start) * 1000)
            }
        }.resume()
    }
}

struct LatencyStatusView: View {
    @ObservedObject var monitor: LatencyMonitor

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 12, weight: .medium))
        }
    }

    private var statusColor: Color {
        guard let latency = monitor.latencyMs else { return .red }
        if latency < 100 { return .green }
        if latency <= 300 { return .yellow }
        return .red
    }

    private var statusText: String {
        guard let latency = monitor.latencyMs else { return "Error" }
        return "\(latency)ms"
    }
}
