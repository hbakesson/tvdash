import SwiftUI

/// Connection details, live traffic and an on-demand internet speed test.
struct NetworkView: View {
    let model: DashboardModel
    let speedTest: SpeedTestModel

    var body: some View {
        DashboardScreen(section: .network) {
            CardColumns {
                SpeedTestCard(model: speedTest)
                DashboardCard(title: "Traffic now", systemImage: "arrow.up.arrow.down", tint: .green) {
                    HStack(spacing: 60) {
                        BigValue(
                            model.throughput.map { ($0.bytesInPerSecond * 8).dataRateText } ?? "–",
                            caption: "Download", tint: .green
                        )
                        BigValue(
                            model.throughput.map { ($0.bytesOutPerSecond * 8).dataRateText } ?? "–",
                            caption: "Upload", tint: .mint
                        )
                    }
                    Sparkline(samples: model.downloadHistory.samples, color: .green, axisFormat: { $0.dataRateText })
                        .frame(height: 180)
                    if let traffic = model.trafficSinceBoot {
                        InfoRow("Received since restart", value: traffic.received.fileText)
                        InfoRow("Sent since restart", value: traffic.sent.fileText)
                    }
                }
            } trailing: {
                DashboardCard(title: "Connection", systemImage: "network", tint: .green) {
                    if let path = model.path {
                        InfoRow("Status", value: String(localized: path.status.title), valueColor: path.status.color)
                        InfoRow("Type", value: String(localized: path.medium.resource))
                        InfoRow("IPv4", value: yesNo(path.supportsIPv4))
                        InfoRow("IPv6", value: yesNo(path.supportsIPv6))
                        InfoRow("DNS", value: yesNo(path.supportsDNS))
                        InfoRow("Low Data Mode", value: yesNo(path.isConstrained))
                        ForEach(path.gateways, id: \.self) { gateway in
                            InfoRow("Router", value: gateway)
                        }
                    } else {
                        ProgressView()
                    }
                }
                DashboardCard(title: "Addresses", systemImage: "number", tint: .green) {
                    if model.interfaces.isEmpty {
                        Text("No IP address")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.interfaces) { interface in
                        ForEach(interface.ipv4 + interface.ipv6, id: \.self) { address in
                            InfoRow(verbatim: interface.name, value: address)
                        }
                    }
                }
            }
        }
    }

    private func yesNo(_ value: Bool) -> String {
        value ? String(localized: "Yes") : String(localized: "No")
    }
}

/// Starts a speed test and shows its progress and latest result. Not focusable itself: its button is.
private struct SpeedTestCard: View {
    let model: SpeedTestModel

    var body: some View {
        DashboardCard(title: "Speed test", systemImage: "speedometer", tint: .green, isFocusable: false) {
            HStack(alignment: .top, spacing: 48) {
                result(\.downloadBitsPerSecond, caption: "Download")
                result(\.uploadBitsPerSecond, caption: "Upload")
                BigValue(
                    model.lastResult.map { "\(Int(($0.latency.seconds * 1000).rounded())) ms" } ?? "–",
                    caption: "Latency"
                )
            }
            HStack(spacing: 32) {
                Button {
                    Task { await model.run() }
                } label: {
                    Label(model.lastResult == nil ? "Test Speed" : "Test Again", systemImage: "play.fill")
                }
                .disabled(model.isRunning)
                status
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func result(_ value: KeyPath<SpeedTestResult, Double>, caption: LocalizedStringKey) -> some View {
        BigValue(model.lastResult.map { $0[keyPath: value].dataRateText } ?? "–", caption: caption, tint: .green)
    }

    @ViewBuilder
    private var status: some View {
        switch model.state {
        case .idle:
            Text("Measures against speed.cloudflare.com")
        case .running(let phase):
            HStack(spacing: 16) {
                ProgressView()
                Text(phase.title)
            }
        case .finished(let result):
            Text("Measured \(result.date, format: .dateTime.hour().minute())")
        case .failed:
            Label("The test failed. Check the connection.", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }
}

extension SpeedTestPhase {
    fileprivate var title: LocalizedStringKey {
        switch self {
        case .latency: "Measuring latency…"
        case .download: "Measuring download…"
        case .upload: "Measuring upload…"
        }
    }
}

extension NetworkPathInfo.Status {
    fileprivate var title: LocalizedStringResource {
        switch self {
        case .connected: "Connected"
        case .disconnected: "Not connected"
        case .requiresConnection: "Waiting for connection"
        }
    }

    fileprivate var color: Color {
        self == .connected ? .green : .orange
    }
}

extension NetworkPathInfo.Medium {
    fileprivate var resource: LocalizedStringResource {
        switch self {
        case .ethernet: "Ethernet"
        case .wifi: "Wi-Fi"
        case .other: "Other"
        case .none: "Not connected"
        }
    }
}

#Preview {
    let model = DashboardModel(provider: PreviewMetrics(), pathMonitor: PreviewPathMonitor())
    NetworkView(model: model, speedTest: SpeedTestModel(service: PreviewSpeedTest()))
        .task { await model.monitor() }
}
