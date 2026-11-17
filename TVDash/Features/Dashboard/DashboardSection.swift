import SwiftUI

/// The dashboard's categories, one tab each.
enum DashboardSection: String, CaseIterable, Identifiable {
    case overview, memory, storage, processor, network, system

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .overview: "Overview"
        case .memory: "Memory"
        case .storage: "Storage"
        case .processor: "Processor"
        case .network: "Network"
        case .system: "System"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .memory: "memorychip"
        case .storage: "internaldrive"
        case .processor: "cpu"
        case .network: "network"
        case .system: "appletv"
        }
    }

    var tint: Color {
        switch self {
        case .overview: .accentColor
        case .memory: .purple
        case .storage: .orange
        case .processor: .blue
        case .network: .green
        case .system: .teal
        }
    }
}
