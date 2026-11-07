import Foundation

/// A column in the returns table.
nonisolated enum ReturnPeriod: CaseIterable, Hashable, Sendable {
    case oneYear, threeYears, fiveYears, tenYears, annualizedTenYears

    /// Years to look back when computing the total return.
    var years: Int {
        switch self {
        case .oneYear: 1
        case .threeYears: 3
        case .fiveYears: 5
        case .tenYears, .annualizedTenYears: 10
        }
    }

    var title: LocalizedStringResource {
        switch self {
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
    /// The start price for "N years" is the last close on or before the same calendar date N years earlier.
    init(history: IndexHistory, calendar: Calendar = .current) {
        var values: [ReturnPeriod: Double] = [:]
        let end = history.updatedAt

        for period in ReturnPeriod.allCases where period != .annualizedTenYears {
            guard
                let target = calendar.date(byAdding: .year, value: -period.years, to: end),
                let start = history.points.last(where: { $0.date <= target })?.close,
                start > 0
            else { continue }
            values[period] = history.latest / start - 1
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
