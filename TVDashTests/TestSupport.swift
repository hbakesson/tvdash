import Foundation

@testable import TVDash

/// A UTC Gregorian calendar so date arithmetic in tests is independent of the machine's settings.
let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
}()

func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    utcCalendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
}

/// Builds a history whose latest value is `latest` on `end`, with the given closes at earlier dates.
func makeHistory(
    symbol: String = "^TEST",
    latest: Double,
    end: Date,
    closes: [(Date, Double)]
) -> IndexHistory {
    IndexHistory(
        symbol: symbol,
        name: symbol,
        currency: "USD",
        baseline: closes.first?.1 ?? latest,
        latest: latest,
        updatedAt: end,
        points: closes.map { IndexHistory.Point(date: $0.0, close: $0.1) } + [.init(date: end, close: latest)]
    )
}
