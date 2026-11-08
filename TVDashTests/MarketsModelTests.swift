import Foundation
import Testing

@testable import TVDash

@Suite("MarketsModel")
struct MarketsModelTests {
    private final class StubProvider: IndexHistoryProviding {
        var failing: Set<String> = []
        private(set) var requests: [(symbol: String, range: HistoryRange)] = []
        let end = date(2026, 11, 6)

        func history(symbol: String, range: HistoryRange, interval: HistoryInterval) async throws -> IndexHistory {
            requests.append((symbol, range))
            if failing.contains(symbol) { throw IndexHistoryError.noData(symbol) }
            // Every index doubled over ten years; growth differs per symbol for the 1-year column.
            let oneYearAgo = symbol == "A" ? 100.0 : 200.0
            return makeHistory(
                symbol: symbol, latest: 400, end: end,
                closes: [(date(2016, 11, 1), 200), (date(2025, 11, 1), oneYearAgo)]
            )
        }
    }

    private let region = MarketRegion(
        id: .global,
        indexes: [
            MarketIndex(symbol: "A", name: "A", currency: "USD"),
            MarketIndex(symbol: "B", name: "B", currency: "USD"),
        ]
    )

    private func makeModel(_ provider: StubProvider) -> MarketsModel {
        MarketsModel(regions: [region], provider: provider, calendar: utcCalendar, now: { provider.end })
    }

    @Test func requestsElevenYearsOfHistoryForEveryIndex() async throws {
        let provider = StubProvider()
        let model = makeModel(provider)

        await model.refresh()

        #expect(Set(provider.requests.map(\.symbol)) == ["A", "B"])
        let range = try #require(provider.requests.first?.range)
        guard case .since(let start) = range else {
            Issue.record("Expected .since range")
            return
        }
        #expect(start <= date(2016, 11, 6))
    }

    @Test func loadsReturnsAndAverage() async throws {
        let model = makeModel(StubProvider())

        await model.refresh()

        guard case .loaded(let a) = model.state(for: region.indexes[0]) else {
            Issue.record("A not loaded")
            return
        }
        #expect(a[.oneYear] == 3.0)
        #expect(a[.tenYears] == 1.0)

        let average = try #require(model.average(for: region))
        #expect(average[.oneYear] == 2.0)
        #expect(model.updatedAt == date(2026, 11, 6))
    }

    @Test func failedIndexIsMarkedAndExcludedFromAverage() async throws {
        let provider = StubProvider()
        provider.failing = ["B"]
        let model = makeModel(provider)

        await model.refresh()

        #expect(model.state(for: region.indexes[1]) == .failed)
        #expect(!model.allFailed)
        let average = try #require(model.average(for: region))
        #expect(average[.oneYear] == 3.0)
    }

    @Test func allFailedWhenNothingLoads() async {
        let provider = StubProvider()
        provider.failing = ["A", "B"]
        let model = makeModel(provider)

        await model.refresh()

        #expect(model.allFailed)
    }

    @Test func keepsDataWhenLaterRefreshFails() async {
        let provider = StubProvider()
        let model = makeModel(provider)
        await model.refresh()

        provider.failing = ["A", "B"]
        await model.refresh()

        #expect(model.allFailed == false)
        #expect(model.state(for: region.indexes[0]) != .failed)
    }

    @Test func noAverageForSingleIndexRegion() async {
        let single = MarketRegion(id: .europe, indexes: [MarketIndex(symbol: "A", name: "A", currency: "EUR")])
        let provider = StubProvider()
        let model = MarketsModel(regions: [single], provider: provider, calendar: utcCalendar, now: { provider.end })

        await model.refresh()

        #expect(model.average(for: single) == nil)
    }
}
