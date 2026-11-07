import Foundation

/// Something that can fetch year-to-date history for an index.
///
/// Views and models depend on this protocol, never on a concrete data source,
/// so tests and previews can supply fake data.
protocol IndexHistoryProviding {
    func yearToDate(symbol: String) async throws -> IndexHistory
}

enum IndexHistoryError: Error, Equatable {
    case invalidSymbol
    case badStatus(Int)
    case noData(String)
}
