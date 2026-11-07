import Foundation

/// The period of history to fetch.
nonisolated enum HistoryRange: Equatable, Sendable {
    /// From the first trading day of the current year.
    case yearToDate
    /// From the given date until now.
    case since(Date)
}

/// Something that can fetch price history for an index.
///
/// Views and models depend on this protocol, never on a concrete data source,
/// so tests and previews can supply fake data.
protocol IndexHistoryProviding: Sendable {
    func history(symbol: String, range: HistoryRange) async throws -> IndexHistory
}

nonisolated enum IndexHistoryError: Error, Equatable {
    case invalidSymbol
    case badStatus(Int)
    case noData(String)
}
