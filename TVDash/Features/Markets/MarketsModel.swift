import Foundation
import OSLog
import Observation

private let logger = Logger(subsystem: "com.hbakesson.tvdash", category: "Markets")

/// Loads long-term returns for every index in every region, so switching region screens is instant.
@Observable
final class MarketsModel {
    enum RowState: Equatable {
        case loading
        case loaded(IndexReturns)
        case failed
    }

    /// Long-term returns change slowly; no need to refresh as often as the OMXS30 screen.
    static let refreshInterval: Duration = .seconds(15 * 60)

    let regions: [MarketRegion]
    private(set) var rows: [MarketIndex.ID: RowState] = [:]
    private(set) var updatedAt: Date?
    private let provider: any IndexHistoryProviding
    private let calendar: Calendar
    private let now: () -> Date

    init(
        regions: [MarketRegion] = MarketRegion.all,
        provider: any IndexHistoryProviding = YahooFinanceService(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = { .now }
    ) {
        self.regions = regions
        self.provider = provider
        self.calendar = calendar
        self.now = now
    }

    func state(for index: MarketIndex) -> RowState {
        rows[index.id] ?? .loading
    }

    /// Average of the loaded indexes in a region, or `nil` if the region has fewer than two indexes.
    func average(for region: MarketRegion) -> IndexReturns? {
        guard region.indexes.count > 1 else { return nil }
        let loaded = region.indexes.compactMap { index -> IndexReturns? in
            if case .loaded(let returns) = state(for: index) { return returns }
            return nil
        }
        return loaded.isEmpty ? nil : .average(of: loaded)
    }

    /// `true` when nothing could be loaded at all – show a full-screen error instead of an empty table.
    var allFailed: Bool {
        let all = regions.flatMap(\.indexes)
        return !all.isEmpty && all.allSatisfy { state(for: $0) == .failed }
    }

    /// Fetches every index concurrently. An index that fails keeps any data it already had.
    func refresh() async {
        let lookback = calendar.date(byAdding: .year, value: -ReturnPeriod.longestLookbackYears, to: now()) ?? now()
        // A couple of extra weeks so there is a close on or before the exact date ten years ago.
        let start = calendar.date(byAdding: .day, value: -14, to: lookback) ?? lookback
        let indexes = regions.flatMap(\.indexes)
        let provider = provider

        await withTaskGroup(of: (MarketIndex, Result<IndexHistory, any Error>).self) { group in
            for index in indexes {
                group.addTask {
                    await Self.fetch(index, since: start, from: provider)
                }
            }

            for await (index, result) in group {
                switch result {
                case .success(let history):
                    rows[index.id] = .loaded(IndexReturns(history: history, calendar: calendar))
                    updatedAt = max(updatedAt ?? history.updatedAt, history.updatedAt)
                case .failure(let error):
                    logger.error(
                        "Failed to load \(index.symbol, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                    if case .loaded = state(for: index) { continue }
                    rows[index.id] = .failed
                }
            }
        }
    }

    private nonisolated static func fetch(
        _ index: MarketIndex, since start: Date, from provider: any IndexHistoryProviding
    ) async -> (MarketIndex, Result<IndexHistory, any Error>) {
        do {
            return (index, .success(try await provider.history(symbol: index.symbol, range: .since(start))))
        } catch {
            return (index, .failure(error))
        }
    }

    /// Shows loading placeholders for failed rows, then refreshes. Used by the "Try Again" button.
    func retry() async {
        for (id, state) in rows where state == .failed {
            rows[id] = .loading
        }
        await refresh()
    }

    /// Refreshes immediately and then periodically until the calling task is cancelled.
    func refreshPeriodically() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: Self.refreshInterval)
        }
    }
}
