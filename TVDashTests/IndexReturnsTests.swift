import Foundation
import Testing

@testable import TVDash

@Suite("IndexReturns")
struct IndexReturnsTests {
    private let end = date(2026, 11, 6)

    @Test func computesReturnsFromCloseOnOrBeforeAnniversary() {
        let history = makeHistory(
            latest: 200,
            end: end,
            closes: [
                (date(2016, 11, 4), 50),  // last close on or before 2016-11-06
                (date(2016, 11, 7), 999),  // after the anniversary – must be ignored
                (date(2021, 11, 5), 100),
                (date(2023, 11, 6), 160),
                (date(2025, 11, 6), 180),
            ]
        )

        let returns = IndexReturns(history: history, calendar: utcCalendar)

        #expect(isClose(returns[.oneYear], 200.0 / 180 - 1))
        #expect(isClose(returns[.threeYears], 200.0 / 160 - 1))
        #expect(isClose(returns[.fiveYears], 1.0))
        #expect(isClose(returns[.tenYears], 3.0))
        #expect(isClose(returns[.annualizedTenYears], pow(4.0, 0.1) - 1))
    }

    @Test func computesShortTermReturns() {
        let history = makeHistory(
            latest: 120,
            end: end,
            closes: [
                (date(2025, 12, 30), 80),  // last close of the previous year
                (date(2026, 1, 2), 999),  // first close of this year – not the YTD baseline
                (date(2026, 5, 6), 90),
                (date(2026, 8, 5), 96),  // last close on or before 2026-08-06
                (date(2026, 10, 6), 100),
            ]
        )

        let returns = IndexReturns(history: history, calendar: utcCalendar)

        #expect(isClose(returns[.oneMonth], 0.2))
        #expect(isClose(returns[.threeMonths], 120.0 / 96 - 1))
        #expect(isClose(returns[.sixMonths], 120.0 / 90 - 1))
        #expect(isClose(returns[.yearToDate], 0.5))
    }

    @Test func noYearToDateWithoutCloseFromPreviousYear() {
        let history = makeHistory(latest: 110, end: end, closes: [(date(2026, 1, 2), 100)])

        let returns = IndexReturns(history: history, calendar: utcCalendar)

        #expect(returns[.yearToDate] == nil)
        #expect(returns[.oneMonth] != nil)
    }

    @Test func missingWhenHistoryIsTooShort() {
        let history = makeHistory(latest: 110, end: end, closes: [(date(2024, 1, 2), 100)])

        let returns = IndexReturns(history: history, calendar: utcCalendar)

        #expect(returns[.oneYear] != nil)
        #expect(returns[.threeYears] == nil)
        #expect(returns[.tenYears] == nil)
        #expect(returns[.annualizedTenYears] == nil)
    }

    @Test func averageIsColumnWiseMeanOfAvailableValues() {
        let a = IndexReturns(values: [.oneYear: 0.10, .tenYears: 1.0, .annualizedTenYears: 0.07])
        let b = IndexReturns(values: [.oneYear: 0.20, .annualizedTenYears: 0.13])

        let average = IndexReturns.average(of: [a, b])

        #expect(isClose(average[.oneYear], 0.15))
        #expect(isClose(average[.tenYears], 1.0))
        #expect(isClose(average[.annualizedTenYears], 0.10))
        #expect(average[.threeYears] == nil)
    }

    private func isClose(_ value: Double?, _ expected: Double) -> Bool {
        guard let value else { return false }
        return abs(value - expected) < 1e-9
    }
}
