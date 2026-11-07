import Foundation
import Testing

@testable import TVDash

@Suite("IndexOverviewModel")
struct IndexOverviewModelTests {
    /// Returns queued results in order; the last one repeats.
    private final class StubProvider: IndexHistoryProviding {
        var results: [Result<IndexHistory, any Error>]
        private(set) var requests: [(symbol: String, range: HistoryRange)] = []

        init(_ results: [Result<IndexHistory, any Error>]) {
            self.results = results
        }

        func history(symbol: String, range: HistoryRange) async throws -> IndexHistory {
            requests.append((symbol, range))
            let result = results.count > 1 ? results.removeFirst() : results[0]
            return try result.get()
        }
    }

    private struct SomeError: Error {}

    @Test func startsInLoadingState() {
        let model = IndexOverviewModel(provider: StubProvider([.success(.preview)]))

        #expect(model.state == .loading)
    }

    @Test func refreshLoadsOMXS30ByDefault() async {
        let provider = StubProvider([.success(.preview)])
        let model = IndexOverviewModel(provider: provider)

        await model.refresh()

        #expect(model.state == .loaded(.preview))
        #expect(provider.requests.map(\.symbol) == ["^OMX"])
        #expect(provider.requests.map(\.range) == [.yearToDate])
    }

    @Test func failureWithoutDataShowsError() async {
        let model = IndexOverviewModel(provider: StubProvider([.failure(SomeError())]))

        await model.refresh()

        #expect(model.state == .failed)
    }

    @Test func failedRefreshKeepsPreviousData() async {
        let model = IndexOverviewModel(provider: StubProvider([.success(.preview), .failure(SomeError())]))

        await model.refresh()
        await model.refresh()

        #expect(model.state == .loaded(.preview))
    }

    @Test func retryRecoversFromFailure() async {
        let model = IndexOverviewModel(provider: StubProvider([.failure(SomeError()), .success(.preview)]))

        await model.refresh()
        await model.retry()

        #expect(model.state == .loaded(.preview))
    }
}
