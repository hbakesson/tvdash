import Foundation

/// How far back an index chart reaches. Chosen with the picker above the chart.
nonisolated enum ChartTimespan: String, CaseIterable, Identifiable, Sendable {
    case oneMonth, threeMonths, sixMonths, yearToDate, oneYear, fiveYears, tenYears, all

    var id: Self { self }

    /// Short label for the picker.
    var title: LocalizedStringResource {
        switch self {
        case .oneMonth: "1M"
        case .threeMonths: "3M"
        case .sixMonths: "6M"
        case .yearToDate: "YTD"
        case .oneYear: "1Y"
        case .fiveYears: "5Y"
        case .tenYears: "10Y"
        case .all: "All"
        }
    }

    /// Describes the period the change is measured over, shown under the change.
    var summary: LocalizedStringResource {
        switch self {
        case .oneMonth: "Past month"
        case .threeMonths: "Past 3 months"
        case .sixMonths: "Past 6 months"
        case .yearToDate: "Since start of year"
        case .oneYear: "Past year"
        case .fiveYears: "Past 5 years"
        case .tenYears: "Past 10 years"
        case .all: "All available history"
        }
    }

    /// Coarser data for long spans keeps the chart light: ~250 points for a year, ~520 for ten.
    var interval: HistoryInterval {
        switch self {
        case .oneMonth, .threeMonths, .sixMonths, .yearToDate, .oneYear: .daily
        case .fiveYears, .tenYears: .weekly
        case .all: .monthly
        }
    }

    /// The history to fetch for a chart ending at `now`.
    func historyRange(endingAt now: Date, calendar: Calendar = .current) -> HistoryRange {
        let lookback: (Calendar.Component, Int)
        switch self {
        case .yearToDate: return .yearToDate
        case .all: return .max
        case .oneMonth: lookback = (.month, 1)
        case .threeMonths: lookback = (.month, 3)
        case .sixMonths: lookback = (.month, 6)
        case .oneYear: lookback = (.year, 1)
        case .fiveYears: lookback = (.year, 5)
        case .tenYears: lookback = (.year, 10)
        }
        return .since(calendar.date(byAdding: lookback.0, value: -lookback.1, to: now) ?? now)
    }
}
