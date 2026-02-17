import Foundation
import SwiftUI
import Combine

final class LatencyMonitor: ObservableObject {
    @Published var latencyMs: Int?
    @Published var isChecking = false

    private let session = URLSession(configuration: .ephemeral)
    private let url = URL(string: "https://captive.apple.com/hotspot-detect.html")!

    func checkNow() {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0
        let start = Date()
        isChecking = true

        session.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false
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
        guard let latency = monitor.latencyMs else { return .gray }
        if latency < 100 { return .green }
        if latency <= 300 { return .yellow }
        return .red
    }

    private var statusText: String {
        guard let latency = monitor.latencyMs else { return monitor.isChecking ? "Checking..." : "Not checked" }
        return "\(latency)ms"
    }
}
