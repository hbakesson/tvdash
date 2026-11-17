import SwiftUI

/// CPU load overall and per core, and the processes the app may see.
struct ProcessorView: View {
    let model: DashboardModel

    var body: some View {
        DashboardScreen(section: .processor) {
            CardColumns {
                DashboardCard(title: "Load", systemImage: "gauge.with.dots.needle.50percent", tint: .blue) {
                    BigValue(model.cpu?.total.percentText ?? "–", caption: "all cores", tint: .blue)
                    InfoRow("User", value: model.cpu?.user.percentText ?? "–")
                    InfoRow("System", value: model.cpu?.system.percentText ?? "–")
                    Sparkline(
                        samples: model.cpuHistory.samples, color: .blue, domain: 0...1,
                        axisFormat: { $0.percentText }
                    )
                    .frame(height: 200)
                }
                DashboardCard(title: "Processes", systemImage: "list.number", tint: .blue) {
                    if let process = model.process {
                        InfoRow("This app (PID \(process.processID))", value: process.cpuUsage.percentText)
                        InfoRow("Threads", value: process.threadCount.formatted())
                        InfoRow("Memory", value: process.memoryFootprint.memoryText)
                    }
                    PlatformLimitNote(
                        text:
                            "tvOS only lets an app see its own process, so a list of the top processes isn't available."
                    )
                }
            } trailing: {
                DashboardCard(title: "Cores", systemImage: "cpu", tint: .blue) {
                    InfoRow(
                        "Active", value: "\(model.device.activeProcessorCount) / \(model.device.processorCount)"
                    )
                    ForEach(Array(model.coreLoads.enumerated()), id: \.offset) { index, load in
                        CoreRow(index: index, load: load)
                    }
                }
            }
        }
    }
}

private struct CoreRow: View {
    let index: Int
    let load: CPULoad

    var body: some View {
        HStack(spacing: 20) {
            Text("Core \(index + 1)")
                .foregroundStyle(.secondary)
                .frame(width: 160, alignment: .leading)
            UsageBar(
                segments: [
                    .init(label: "System", fraction: load.system, color: .red),
                    .init(label: "User", fraction: load.user, color: .blue),
                ],
                height: 22
            )
            Text(verbatim: load.total.percentText)
                .monospacedDigit()
                .frame(width: 110, alignment: .trailing)
        }
        .font(.callout)
    }
}

#Preview {
    let model = DashboardModel(provider: PreviewMetrics(), pathMonitor: PreviewPathMonitor())
    ProcessorView(model: model)
        .task { await model.monitor() }
}
