import SwiftUI

/// System RAM broken down by kind, its recent history, and this app's share.
struct MemoryView: View {
    let model: DashboardModel

    var body: some View {
        DashboardScreen(section: .memory) {
            if let memory = model.memory {
                DashboardCard(title: "RAM", systemImage: "memorychip", tint: .purple) {
                    BigValue(
                        memory.used.memoryText, caption: "in use of \(memory.total.memoryText)",
                        tint: .purple
                    )
                    UsageBar(segments: segments(memory))
                    UsageLegend(segments: segments(memory))
                }

                CardColumns {
                    DashboardCard(title: "Breakdown", systemImage: "list.bullet", tint: .purple) {
                        InfoRow("Total", value: memory.total.memoryText)
                        InfoRow("Available", value: memory.available.memoryText, valueColor: .green)
                        InfoRow("Wired", value: memory.wired.memoryText)
                        InfoRow("Active", value: memory.active.memoryText)
                        InfoRow("Inactive", value: memory.inactive.memoryText)
                        InfoRow("Compressed", value: memory.compressed.memoryText)
                        InfoRow("Free", value: memory.free.memoryText)
                    }
                } trailing: {
                    DashboardCard(title: "Last 2 minutes", systemImage: "chart.xyaxis.line", tint: .purple) {
                        Sparkline(
                            samples: model.memoryHistory.samples, color: .purple, domain: 0...1,
                            axisFormat: { $0.percentText }
                        )
                        .frame(height: 220)
                    }
                    if let process = model.process {
                        DashboardCard(title: "This app", systemImage: "app.badge", tint: .purple) {
                            InfoRow("Footprint", value: process.memoryFootprint.memoryText)
                            InfoRow("May still allocate", value: process.memoryAvailable.memoryText)
                            InfoRow("Limit", value: process.memoryLimit.memoryText)
                        }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func segments(_ memory: MemoryStats) -> [UsageBar.Segment] {
        let total = Double(max(memory.total, 1))
        return [
            .init(label: "Wired", fraction: Double(memory.wired) / total, color: .red),
            .init(label: "Active", fraction: Double(memory.active) / total, color: .purple),
            .init(label: "Compressed", fraction: Double(memory.compressed) / total, color: .yellow),
            .init(label: "Inactive", fraction: Double(memory.inactive) / total, color: .indigo.opacity(0.6)),
        ]
    }
}

#Preview {
    let model = DashboardModel(provider: PreviewMetrics(), pathMonitor: PreviewPathMonitor())
    MemoryView(model: model)
        .task { await model.monitor() }
}
