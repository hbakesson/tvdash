import SwiftUI

/// The start screen: one tile per category with its headline figure. Selecting a tile opens the category.
struct OverviewView: View {
    let model: DashboardModel
    @Binding var selection: DashboardSection

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 48), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 48) {
            OverviewTile(section: .memory, selection: $selection) {
                if let memory = model.memory {
                    BigValue(
                        memory.usedFraction.percentText, caption: "RAM in use", tint: DashboardSection.memory.tint,
                        size: 60)
                    Text("\(memory.available.memoryText) available of \(memory.total.memoryText)")
                } else {
                    BigValue("–", size: 60)
                }
            } chart: {
                Sparkline(samples: model.memoryHistory.samples, color: .purple, domain: 0...1)
            }

            OverviewTile(section: .storage, selection: $selection) {
                if let storage = model.storage {
                    BigValue(
                        storage.volumeAvailable.fileText, caption: "free", tint: DashboardSection.storage.tint, size: 60
                    )
                    Text("\(storage.volumeUsed.fileText) used of \(storage.volumeTotal.fileText)")
                } else {
                    BigValue("–", size: 60)
                }
            } chart: {
                UsageBar(fraction: model.storage?.usedFraction ?? 0, color: .orange)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }

            OverviewTile(section: .processor, selection: $selection) {
                BigValue(
                    model.cpu?.total.percentText ?? "–", caption: "CPU load", tint: DashboardSection.processor.tint,
                    size: 60
                )
                Text("\(model.device.activeProcessorCount) cores")
            } chart: {
                Sparkline(samples: model.cpuHistory.samples, color: .blue, domain: 0...1)
            }

            OverviewTile(section: .network, selection: $selection) {
                BigValue(
                    "↓ " + (model.throughput.map { ($0.bytesInPerSecond * 8).dataRateText } ?? "–"),
                    tint: DashboardSection.network.tint,
                    size: 60
                )
                HStack(spacing: 12) {
                    Text(verbatim: "↑ " + (model.throughput.map { ($0.bytesOutPerSecond * 8).dataRateText } ?? "–"))
                    Text(verbatim: "·")
                    Text(model.path?.medium.title ?? "Unknown")
                }
            } chart: {
                Sparkline(samples: model.downloadHistory.samples, color: .green)
            }

            OverviewTile(
                section: .system, title: "Uptime", systemImage: "clock.arrow.circlepath", selection: $selection
            ) {
                BigValue(model.uptime?.shortDurationText ?? "–", caption: "since restart", tint: .teal, size: 60)
                if let bootDate = model.bootDate {
                    Text("Restarted \(bootDate, format: .dateTime.day().month().hour().minute())")
                }
            } chart: {
                EmptyView()
            }

            OverviewTile(section: .system, selection: $selection) {
                BigValue("\(model.device.systemName) \(model.device.systemVersion)", tint: .teal, size: 60)
                Text(verbatim: model.device.modelName)
            } chart: {
                EmptyView()
            }
        }
        .padding(.vertical, 24)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// A selectable summary of one category.
private struct OverviewTile<Summary: View, Chart: View>: View {
    let section: DashboardSection
    var title: LocalizedStringKey?
    var systemImage: String?
    @Binding var selection: DashboardSection
    @ViewBuilder let summary: Summary
    @ViewBuilder let chart: Chart

    var body: some View {
        Button {
            selection = section
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                Label(title ?? section.title, systemImage: systemImage ?? section.systemImage)
                    .font(.headline)
                    .foregroundStyle(section.tint)
                VStack(alignment: .leading, spacing: 8) { summary }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                chart
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer(minLength: 0)
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: 400, alignment: .top)
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
    }
}

extension NetworkPathInfo.Medium {
    var title: LocalizedStringKey {
        switch self {
        case .ethernet: "Ethernet"
        case .wifi: "Wi-Fi"
        case .other: "Other"
        case .none: "Not connected"
        }
    }
}

#Preview {
    @Previewable @State var selection = DashboardSection.overview
    let model = DashboardModel(provider: PreviewMetrics(), pathMonitor: PreviewPathMonitor())
    OverviewView(model: model, selection: $selection)
        .task { await model.monitor() }
}
