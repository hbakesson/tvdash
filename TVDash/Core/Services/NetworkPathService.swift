import Foundation
import Network

/// `NetworkPathMonitoring` backed by `NWPathMonitor`.
struct NetworkPathService: NetworkPathMonitoring {
    func paths() -> AsyncStream<NetworkPathInfo> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                continuation.yield(Self.info(from: path))
            }
            continuation.onTermination = { _ in monitor.cancel() }
            monitor.start(queue: DispatchQueue(label: "com.hbakesson.tvdash.path-monitor"))
        }
    }

    private nonisolated static func info(from path: NWPath) -> NetworkPathInfo {
        let status: NetworkPathInfo.Status =
            switch path.status {
            case .satisfied: .connected
            case .requiresConnection: .requiresConnection
            default: .disconnected
            }
        let medium: NetworkPathInfo.Medium =
            if path.usesInterfaceType(.wiredEthernet) {
                .ethernet
            } else if path.usesInterfaceType(.wifi) {
                .wifi
            } else if path.status == .satisfied {
                .other
            } else {
                .none
            }
        let gateways = path.gateways.compactMap { endpoint -> String? in
            guard case .hostPort(let host, _) = endpoint else { return nil }
            return switch host {
            case .ipv4(let address): "\(address)"
            case .ipv6(let address): "\(address)".split(separator: "%").first.map(String.init)
            case .name(let name, _): name
            @unknown default: nil
            }
        }
        return NetworkPathInfo(
            status: status,
            medium: medium,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            supportsIPv4: path.supportsIPv4,
            supportsIPv6: path.supportsIPv6,
            supportsDNS: path.supportsDNS,
            gateways: gateways
        )
    }
}
