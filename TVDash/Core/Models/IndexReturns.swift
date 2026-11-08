import Foundation

/// A column in the returns table.
nonisolated enum ReturnPeriod: CaseIterable, Hashable, Sendable {
    case oneMonth, threeMonths, sixMonths, yearToDate
    case oneYear, threeYears, fiveYears, tenYears, annualizedTenYears

    /// How far back from the latest value the start price is taken, or `nil` for periods with their own rule.
    var lookback: (component: Calendar.Component, value: Int)? {
        switch self {
        case .oneMonth: (.month, 1)
        case .threeMonths: (.month, 3)
        case .sixMonths: (.month, 6)
        case .oneYear: (.year, 1)
        case .threeYears: (.year, 3)
        case .fiveYears: (.year, 5)
        case .tenYears: (.year, 10)
        case .yearToDate, .annualizedTenYears: nil
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .oneMonth: "1M"
        case .threeMonths: "3M"
        case .sixMonths: "6M"
        case .yearToDate: "YTD"
        case .oneYear: "1 yr"
        case .threeYears: "3 yrs"
        case .fiveYears: "5 yrs"
        case .tenYears: "10 yrs"
        case .annualizedTenYears: "Per year, 10 yrs"
        }
    }

    /// How far back history must be fetched to fill every column.
    static let longestLookbackYears = 10
}

/// Price returns (excluding dividends) for one index, as fractions (0.05 = +5 %).
///
/// A value is missing when the history does not reach far enough back.
nonisolated struct IndexReturns: Equatable, Sendable {
    private(set) var values: [ReturnPeriod: Double]

    init(values: [ReturnPeriod: Double]) {
        self.values = values
    }

    subscript(period: ReturnPeriod) -> Double? { values[period] }

    /// Computes returns from daily history, measured back from the latest value.
    ///
    /// The start price for "N months/years" is the last close on or before the same calendar date that long
    /// before. For year-to-date it is the last close of the previous year.
    init(history: IndexHistory, calendar: Calendar = .current) {
        var values: [ReturnPeriod: Double] = [:]
        let end = history.updatedAt

        /// Last positive close before `date` (or on it, if `inclusive`).
        func lastClose(before date: Date, inclusive: Bool) -> Double? {
            let point = history.points.last { inclusive ? $0.date <= date : $0.date < date }
            guard let close = point?.close, close > 0 else { return nil }
            return close
        }

        for period in ReturnPeriod.allCases {
            guard
                let lookback = period.lookback,
                let target = calendar.date(byAdding: lookback.component, value: -lookback.value, to: end),
                let start = lastClose(before: target, inclusive: true)
            else { continue }
            values[period] = history.latest / start - 1
        }

        if let startOfYear = calendar.dateInterval(of: .year, for: end)?.start,
            let start = lastClose(before: startOfYear, inclusive: false)
        {
            values[.yearToDate] = history.latest / start - 1
        }

        if let tenYears = values[.tenYears] {
            values[.annualizedTenYears] = pow(1 + tenYears, 1.0 / 10) - 1
        }

        self.values = values
    }

    /// Column-wise arithmetic mean, using only the indexes that have a value for each column.
    static func average(of returns: [IndexReturns]) -> IndexReturns {
        var values: [ReturnPeriod: Double] = [:]
        for period in ReturnPeriod.allCases {
            let available = returns.compactMap { $0[period] }
            guard !available.isEmpty else { continue }
            values[period] = available.reduce(0, +) / Double(available.count)
        }
        return IndexReturns(values: values)
    }
}
