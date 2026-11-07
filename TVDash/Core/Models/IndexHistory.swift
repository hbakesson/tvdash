import Foundation

/// Daily closing prices for a stock index over some period, plus the latest value.
///
/// `nonisolated` so it can be built and processed off the main actor.
nonisolated struct IndexHistory: Equatable, Sendable {
    struct Point: Identifiable, Equatable, Sendable {
        let date: Date
        let close: Double

        var id: Date { date }
    }

    /// Ticker symbol, e.g. `^OMX`.
    let symbol: String
    /// Human-readable name, e.g. "OMX Stockholm 30 Index".
    let name: String
    /// ISO currency code, e.g. "SEK".
    let currency: String
    /// Close just before the first point – for year-to-date data, last close of the previous year.
    let baseline: Double
    /// Most recent index value.
    let latest: Double
    /// Time of the most recent value.
    let updatedAt: Date
    /// Daily closes, oldest first.
    let points: [Point]

    /// Year-to-date change in index points.
    var change: Double { latest - baseline }

    /// Year-to-date change as a fraction (0.05 = +5 %).
    var changeFraction: Double {
        guard baseline != 0 else { return 0 }
        return change / baseline
    }

    var isUp: Bool { change >= 0 }

    /// Value range covering all points and the baseline, for chart scaling.
    var valueRange: ClosedRange<Double> {
        let values = points.map(\.close) + [baseline, latest]
        let low = values.min() ?? baseline
        let high = values.max() ?? baseline
        return low...high
    }
}
