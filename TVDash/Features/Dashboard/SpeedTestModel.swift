import Foundation
import OSLog
import Observation

private let logger = Logger(subsystem: "com.hbakesson.tvdash", category: "SpeedTest")

/// Runs an internet speed test on request and keeps the latest result.
@Observable
final class SpeedTestModel {
    enum State: Equatable {
        case idle
        case running(SpeedTestPhase)
        case finished(SpeedTestResult)
        case failed
    }

    private(set) var state: State = .idle
    /// The most recent successful result, kept while a new test runs or after one fails.
    private(set) var lastResult: SpeedTestResult?
    private let service: any SpeedTesting

    init(service: any SpeedTesting = CloudflareSpeedTestService()) {
        self.service = service
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    /// Runs one test. Ignored while a test is already running.
    func run() async {
        guard !isRunning else { return }
        state = .running(.latency)
        do {
            let result = try await service.run { [weak self] phase in
                await self?.advance(to: phase)
            }
            lastResult = result
            state = .finished(result)
        } catch {
            logger.error("Speed test failed: \(error.localizedDescription, privacy: .public)")
            state = .failed
        }
    }

    private func advance(to phase: SpeedTestPhase) {
        if isRunning { state = .running(phase) }
    }
}
