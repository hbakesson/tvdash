import Foundation
import OSLog
import Observation

private let logger = Logger(subsystem: "com.hbakesson.tvdash", category: "IndexOverview")

/// Loads and holds chart data for one index (OMXS30 by default), one history per timespan.
///
/// Each timespan is cached separately, so switching back to a timespan already seen is instant.
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
    private(set) var states: [ChartTimespan: State] = [:]
    private let provider: any IndexHistoryProviding
    private let calendar: Calendar
    private let now: () -> Date

    init(
        symbol: String = "^OMX",
        displayName: String = "OMXS30",
        provider: any IndexHistoryProviding = YahooFinanceService(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = { .now }
    ) {
        self.symbol = symbol
        self.displayName = displayName
        self.provider = provider
        self.calendar = calendar
        self.now = now
    }

    func state(for timespan: ChartTimespan) -> State {
        states[timespan] ?? .loading
    }

    /// Fetches fresh data for a timespan. If a refresh fails after data has been shown, the old data stays on screen.
    func refresh(_ timespan: ChartTimespan) async {
        do {
            let history = try await provider.history(
                symbol: symbol,
                range: timespan.historyRange(endingAt: now(), calendar: calendar),
                interval: timespan.interval
            )
            states[timespan] = .loaded(history)
        } catch {
            // Switching timespan cancels the fetch for the old one; that is not a failure.
            if Task.isCancelled || error is CancellationError { return }
            logger.error(
                "Failed to load \(self.symbol, privacy: .public): \(error.localizedDescription, privacy: .public)")
            if case .loaded = state(for: timespan) { return }
            states[timespan] = .failed
        }
    }

    /// Shows the loading state, then refreshes. Used by the "Try Again" button.
    func retry(_ timespan: ChartTimespan) async {
        states[timespan] = .loading
        await refresh(timespan)
    }

    /// Refreshes immediately and then periodically until the calling task is cancelled.
    func refreshPeriodically(_ timespan: ChartTimespan) async {
        while !Task.isCancelled {
            await refresh(timespan)
            try? await Task.sleep(for: Self.refreshInterval)
        }
    }
}
