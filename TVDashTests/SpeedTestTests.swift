import Foundation
import Testing

@testable import TVDash

@Suite("SpeedTestModel")
struct SpeedTestModelTests {
    private final class StubService: SpeedTesting {
        var result: Result<SpeedTestResult, SpeedTestError>
        private(set) var phases: [SpeedTestPhase] = []

        init(result: Result<SpeedTestResult, SpeedTestError>) {
            self.result = result
        }

        func run(progress: @escaping @Sendable (SpeedTestPhase) async -> Void) async throws -> SpeedTestResult {
            for phase in [SpeedTestPhase.latency, .download, .upload] {
                await progress(phase)
            }
            return try result.get()
        }
    }

    private static let result = SpeedTestResult(
        latency: .milliseconds(10), downloadBitsPerSecond: 100e6, uploadBitsPerSecond: 20e6, date: referenceDate
    )

    @Test func finishesWithResult() async {
        let model = SpeedTestModel(service: StubService(result: .success(Self.result)))

        await model.run()

        #expect(model.state == .finished(Self.result))
        #expect(model.lastResult == Self.result)
        #expect(!model.isRunning)
    }

    @Test func failureKeepsPreviousResult() async {
        let service = StubService(result: .success(Self.result))
        let model = SpeedTestModel(service: service)
        await model.run()

        service.result = .failure(.badStatus(500))
        await model.run()

        #expect(model.state == .failed)
        #expect(model.lastResult == Self.result)
    }
}

@Suite("CloudflareSpeedTestService")
struct CloudflareSpeedTestServiceTests {
    private final class FakeTransport: HTTPTransport, @unchecked Sendable {
        var status = 200
        private(set) var requests: [URLRequest] = []
        private(set) var uploadedBytes: [Int] = []

        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            requests.append(request)
            return (Data(), response(for: request))
        }

        func upload(for request: URLRequest, from body: Data) async throws -> (Data, URLResponse) {
            requests.append(request)
            uploadedBytes.append(body.count)
            return (Data(), response(for: request))
        }

        private func response(for request: URLRequest) -> URLResponse {
            HTTPURLResponse(
                url: request.url ?? URL(fileURLWithPath: "/"), statusCode: status, httpVersion: nil, headerFields: nil)
                ?? URLResponse()
        }
    }

    @Test func probesLatencyThenDownloadsThenUploads() async throws {
        let transport = FakeTransport()
        let service = CloudflareSpeedTestService(transport: transport)

        let result = try await service.run { _ in }

        let urls = transport.requests.compactMap(\.url?.absoluteString)
        #expect(urls.count == CloudflareSpeedTestService.latencyProbes + 2)
        #expect(urls.first == "https://speed.cloudflare.com/__down?bytes=0")
        #expect(urls.dropLast().last == "https://speed.cloudflare.com/__down?bytes=25000000")
        #expect(urls.last == "https://speed.cloudflare.com/__up")
        #expect(transport.requests.last?.httpMethod == "POST")
        #expect(transport.uploadedBytes == [CloudflareSpeedTestService.uploadBytes])
        #expect(result.downloadBitsPerSecond >= 0)
    }

    @Test func badStatusFailsTheTest() async {
        let transport = FakeTransport()
        transport.status = 503
        let service = CloudflareSpeedTestService(transport: transport)

        await #expect(throws: SpeedTestError.badStatus(503)) {
            try await service.run { _ in }
        }
    }

    @Test func medianIgnoresOutliers() {
        let values: [Duration] = [.milliseconds(300), .milliseconds(10), .milliseconds(12), .milliseconds(11)]

        #expect(CloudflareSpeedTestService.median(values) == .milliseconds(12))
        #expect(CloudflareSpeedTestService.median([]) == .zero)
    }
}
