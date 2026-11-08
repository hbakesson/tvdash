import Foundation

/// The period of history to fetch.
nonisolated enum HistoryRange: Equatable, Sendable {
    /// From the first trading day of the current year.
    case yearToDate
    /// From the given date until now.
    case since(Date)
    /// All history the data source has.
    case max
}

/// Spacing between data points.
nonisolated enum HistoryInterval: Equatable, Sendable {
    case daily, weekly, monthly
}

/// Something that can fetch price history for an index.
///
/// Views and models depend on this protocol, never on a concrete data source,
/// so tests and previews can supply fake data.
protocol IndexHistoryProviding: Sendable {
    func history(symbol: String, range: HistoryRange, interval: HistoryInterval) async throws -> IndexHistory
}

extension IndexHistoryProviding {
    /// Daily closes for the given range.
    func history(symbol: String, range: HistoryRange) async throws -> IndexHistory {
        try await history(symbol: symbol, range: range, interval: .daily)
    }
}

nonisolated enum IndexHistoryError: Error, Equatable {
    case invalidSymbol
    case badStatus(Int)
    case noData(String)
}
