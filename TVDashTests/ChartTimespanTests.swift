import Foundation
import Testing

@testable import TVDash

@Suite("ChartTimespan")
struct ChartTimespanTests {
    private let now = date(2026, 11, 6)

    @Test(arguments: [
        (ChartTimespan.oneMonth, date(2026, 10, 6)),
        (.threeMonths, date(2026, 8, 6)),
        (.sixMonths, date(2026, 5, 6)),
        (.oneYear, date(2025, 11, 6)),
        (.fiveYears, date(2021, 11, 6)),
        (.tenYears, date(2016, 11, 6)),
    ])
    func fixedSpansLookBackFromNow(timespan: ChartTimespan, start: Date) {
        #expect(timespan.historyRange(endingAt: now, calendar: utcCalendar) == .since(start))
    }

    @Test func yearToDateAndAllUseOpenRanges() {
        #expect(ChartTimespan.yearToDate.historyRange(endingAt: now, calendar: utcCalendar) == .yearToDate)
        #expect(ChartTimespan.all.historyRange(endingAt: now, calendar: utcCalendar) == .max)
    }

    @Test func longerSpansUseCoarserData() {
        #expect(ChartTimespan.oneYear.interval == .daily)
        #expect(ChartTimespan.tenYears.interval == .weekly)
        #expect(ChartTimespan.all.interval == .monthly)
    }

    @Test func storedSelectionRoundTrips() {
        for timespan in ChartTimespan.allCases {
            #expect(ChartTimespan(rawValue: timespan.rawValue) == timespan)
        }
    }
}
