import SwiftUI

/// Device, software, time and regional settings.
struct SystemView: View {
    let model: DashboardModel

    private var device: DeviceInfo { model.device }

    var body: some View {
        DashboardScreen(section: .system) {
            CardColumns {
                DashboardCard(title: "Device", systemImage: "appletv", tint: .teal) {
                    InfoRow("Name", value: device.name)
                    InfoRow("Model", value: device.modelName)
                    InfoRow("Identifier", value: device.modelIdentifier)
                    if device.isSimulator {
                        InfoRow("Runs in", value: String(localized: "Simulator"), valueColor: .orange)
                    }
                    InfoRow("CPU cores", value: device.processorCount.formatted())
                    InfoRow("RAM", value: device.physicalMemory.memoryText)
                }
                DashboardCard(title: "Software", systemImage: "gearshape.2", tint: .teal) {
                    InfoRow("\(device.systemName) version", value: device.systemVersion)
                    InfoRow("Build", value: device.systemBuild)
                    InfoRow("Darwin kernel", value: device.kernelVersion)
                    InfoRow("This app", value: "\(device.appVersion) (\(device.appBuild))")
                }
            } trailing: {
                DashboardCard(title: "Time", systemImage: "clock", tint: .teal) {
                    InfoRow("Uptime", value: model.uptime?.durationText ?? "–")
                    if let bootDate = model.bootDate {
                        InfoRow("Last restart", value: bootDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    InfoRow("App started", value: device.launchDate.formatted(date: .omitted, time: .shortened))
                    if let thermal = model.thermalState {
                        InfoRow("Temperature", value: String(localized: thermal.title), valueColor: thermal.color)
                    }
                }
                DashboardCard(title: "Region", systemImage: "globe", tint: .teal) {
                    InfoRow("Language", value: Self.languageName)
                    InfoRow("Region", value: Self.regionName)
                    InfoRow("Time zone", value: TimeZone.current.identifier)
                }
            }
        }
    }

    private static var languageName: String {
        let locale = Locale.current
        return locale.language.languageCode.flatMap { locale.localizedString(forLanguageCode: $0.identifier) } ?? "–"
    }

    private static var regionName: String {
        let locale = Locale.current
        return locale.region.flatMap { locale.localizedString(forRegionCode: $0.identifier) } ?? "–"
    }
}

extension ThermalState {
    fileprivate var title: LocalizedStringResource {
        switch self {
        case .nominal: "Normal"
        case .fair: "Slightly elevated"
        case .serious: "High"
        case .critical: "Critical"
        }
    }

    fileprivate var color: Color {
        switch self {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        }
    }
}

#Preview {
    let model = DashboardModel(provider: PreviewMetrics(), pathMonitor: PreviewPathMonitor())
    SystemView(model: model)
        .task { await model.monitor() }
}
