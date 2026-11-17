import Foundation

/// The current network route, from `NWPathMonitor`.
nonisolated struct NetworkPathInfo: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case connected, disconnected, requiresConnection
    }

    enum Medium: Equatable, Sendable {
        case ethernet, wifi, other, none
    }

    var status: Status
    var medium: Medium
    var isExpensive: Bool
    var isConstrained: Bool
    var supportsIPv4: Bool
    var supportsIPv6: Bool
    var supportsDNS: Bool
    /// Router addresses.
    var gateways: [String]
}
