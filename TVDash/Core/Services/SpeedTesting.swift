import Foundation

/// Measures internet latency and throughput.
protocol SpeedTesting: Sendable {
    /// Runs a full test. `progress` is called as each phase starts.
    func run(progress: @escaping @Sendable (SpeedTestPhase) async -> Void) async throws -> SpeedTestResult
}

nonisolated enum SpeedTestError: Error, Equatable {
    case badStatus(Int)
}

/// The HTTP calls a speed test needs, so tests can replace the network.
protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    func upload(for request: URLRequest, from body: Data) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
    nonisolated func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }

    nonisolated func upload(for request: URLRequest, from body: Data) async throws -> (Data, URLResponse) {
        try await upload(for: request, from: body, delegate: nil)
    }
}
