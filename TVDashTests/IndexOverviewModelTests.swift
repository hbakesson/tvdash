import Foundation
import Testing

@testable import TVDash

@Suite("IndexOverviewModel")
struct IndexOverviewModelTests {
    /// Returns queued results in order; the last one repeats.
    private final class StubProvider: IndexHistoryProviding {
        var results: [Result<IndexHistory, any Error>]
        private(set) var requests: [(symbol: String, range: HistoryRange, interval: HistoryInterval)] = []

        init(_ results: [Result<IndexHistory, any Error>]) {
            self.results = results
        }

        func history(symbol: String, range: HistoryRange, interval: HistoryInterval) async throws -> IndexHistory {
            requests.append((symbol, range, interval))
            let result = results.count > 1 ? results.removeFirst() : results[0]
            return try result.get()
        }
    }

    private struct SomeError: Error {}

    private func makeModel(_ provider: StubProvider) -> IndexOverviewModel {
        IndexOverviewModel(provider: provider, calendar: utcCalendar, now: { date(2026, 11, 6) })
    }

    @Test func startsInLoadingState() {
        let model = makeModel(StubProvider([.success(.preview)]))

        #expect(model.state(for: .yearToDate) == .loading)
    }

    @Test func refreshLoadsOMXS30ByDefault() async {
        let provider = StubProvider([.success(.preview)])
        let model = makeModel(provider)

        await model.refresh(.yearToDate)

        #expect(model.state(for: .yearToDate) == .loaded(.preview))
        #expect(provider.requests.map(\.symbol) == ["^OMX"])
        #expect(provider.requests.map(\.range) == [.yearToDate])
        #expect(provider.requests.map(\.interval) == [.daily])
    }

    @Test func requestsRangeAndIntervalForTimespan() async {
        let provider = StubProvider([.success(.preview)])
        let model = makeModel(provider)

        await model.refresh(.fiveYears)

        #expect(provider.requests.map(\.range) == [.since(date(2021, 11, 6))])
        #expect(provider.requests.map(\.interval) == [.weekly])
    }

    @Test func timespansAreCachedSeparately() async {
        let model = makeModel(StubProvider([.success(.preview)]))

        await model.refresh(.oneMonth)

        #expect(model.state(for: .oneMonth) == .loaded(.preview))
        #expect(model.state(for: .oneYear) == .loading)
    }

    @Test func failureWithoutDataShowsError() async {
        let model = makeModel(StubProvider([.failure(SomeError())]))

        await model.refresh(.yearToDate)

        #expect(model.state(for: .yearToDate) == .failed)
    }

    @Test func failedRefreshKeepsPreviousData() async {
        let model = makeModel(StubProvider([.success(.preview), .failure(SomeError())]))

        await model.refresh(.yearToDate)
        await model.refresh(.yearToDate)

        #expect(model.state(for: .yearToDate) == .loaded(.preview))
    }

    @Test func retryRecoversFromFailure() async {
        let model = makeModel(StubProvider([.failure(SomeError()), .success(.preview)]))

        await model.refresh(.yearToDate)
        await model.retry(.yearToDate)

        #expect(model.state(for: .yearToDate) == .loaded(.preview))
    }
}
