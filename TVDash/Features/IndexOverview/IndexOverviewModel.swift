import Foundation
import OSLog
import Observation

private let logger = Logger(subsystem: "com.hbakesson.tvdash", category: "IndexOverview")

/// Loads and holds year-to-date data for one index (OMXS30 by default).
@Observable
final class IndexOverviewModel {
    enum State: Equatable {
        case loading
        case loaded(IndexHistory)
        case failed
    }

    /// How often to fetch new data while the screen is visible.
    static let refreshInterval: Duration = .seconds(5 * 60)

    let symbol: String
    let displayName: String
    private(set) var state: State = .loading
    private let provider: any IndexHistoryProviding

    init(
        symbol: String = "^OMX",
        displayName: String = "OMXS30",
        provider: any IndexHistoryProviding = YahooFinanceService()
    ) {
        self.symbol = symbol
        self.displayName = displayName
        self.provider = provider
    }

    /// Fetches fresh data. If a refresh fails after data has been shown, the old data stays on screen.
    func refresh() async {
        do {
            state = .loaded(try await provider.history(symbol: symbol, range: .yearToDate))
        } catch is CancellationError {
            return
        } catch {
            logger.error(
                "Failed to load \(self.symbol, privacy: .public): \(error.localizedDescription, privacy: .public)")
            if case .loaded = state { return }
            state = .failed
        }
    }

    /// Shows the loading state, then refreshes. Used by the "Try Again" button.
    func retry() async {
        state = .loading
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
