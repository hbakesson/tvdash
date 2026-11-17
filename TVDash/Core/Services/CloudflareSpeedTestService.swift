import Foundation

/// Speed test against Cloudflare's public speed test endpoints (`speed.cloudflare.com`), which need no API key.
///
/// Only zero-filled test data is sent; see `docs/adr/0005-speed-test-via-cloudflare.md`.
struct CloudflareSpeedTestService: SpeedTesting {
    static let baseURL = URL(string: "https://speed.cloudflare.com")
    static let latencyProbes = 5
    static let downloadBytes = 25_000_000
    static let uploadBytes = 10_000_000

    var transport: any HTTPTransport = Self.makeSession()
    var clock = ContinuousClock()

    func run(progress: @escaping @Sendable (SpeedTestPhase) async -> Void) async throws -> SpeedTestResult {
        await progress(.latency)
        var probes: [Duration] = []
        for _ in 0..<Self.latencyProbes {
            probes.append(try await timed { try await download(bytes: 0) })
        }
        let latency = Self.median(probes)

        await progress(.download)
        let downloadTime = try await timed { try await download(bytes: Self.downloadBytes) }

        await progress(.upload)
        let uploadTime = try await timed { try await upload(bytes: Self.uploadBytes) }

        return SpeedTestResult(
            latency: latency,
            downloadBitsPerSecond: SpeedTestResult.bitsPerSecond(
                bytes: Self.downloadBytes, duration: max(.zero, downloadTime - latency)
            ),
            uploadBitsPerSecond: SpeedTestResult.bitsPerSecond(
                bytes: Self.uploadBytes, duration: max(.zero, uploadTime - latency)
            ),
            date: .now
        )
    }

    /// The middle value, so one slow probe (DNS lookup, TLS handshake) does not skew the latency.
    nonisolated static func median(_ values: [Duration]) -> Duration {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return .zero }
        return sorted[sorted.count / 2]
    }

    private func timed(_ work: () async throws -> Void) async throws -> Duration {
        let start = clock.now
        try await work()
        return clock.now - start
    }

    private func download(bytes: Int) async throws {
        guard
            let url = Self.baseURL?.appending(path: "__down").appending(queryItems: [
                URLQueryItem(name: "bytes", value: String(bytes))
            ])
        else { return }
        let (_, response) = try await transport.data(for: URLRequest(url: url))
        try Self.check(response)
    }

    private func upload(bytes: Int) async throws {
        guard let url = Self.baseURL?.appending(path: "__up") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await transport.upload(for: request, from: Data(count: bytes))
        try Self.check(response)
    }

    private nonisolated static func check(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SpeedTestError.badStatus(http.statusCode)
        }
    }

    /// No caching and no cookies, so every test really goes over the network.
    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }
}
