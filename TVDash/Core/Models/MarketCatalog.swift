import Foundation

/// An index shown on a region screen.
nonisolated struct MarketIndex: Identifiable, Hashable, Sendable {
    /// Yahoo Finance symbol, e.g. `^GSPC`.
    let symbol: String
    /// Display name, e.g. "S&P 500".
    let name: String
    /// Currency the index is quoted in.
    let currency: String
    /// If the index is tracked through an ETF, the ETF's name.
    let proxy: String?

    var id: String { symbol }

    init(symbol: String, name: String, currency: String, proxy: String? = nil) {
        self.symbol = symbol
        self.name = name
        self.currency = currency
        self.proxy = proxy
    }
}

/// A group of indexes shown together on one screen.
nonisolated struct MarketRegion: Identifiable, Hashable, Sendable {
    enum ID: String, Hashable, Sendable {
        case global, northAmerica, europe, nordics, asiaAndEmerging
    }

    let id: ID
    let indexes: [MarketIndex]

    var title: LocalizedStringResource {
        switch id {
        case .global: "Global"
        case .northAmerica: "North America"
        case .europe: "Europe"
        case .nordics: "Nordics"
        case .asiaAndEmerging: "Asia & Emerging Markets"
        }
    }
}

nonisolated extension MarketRegion {
    /// All regions, in display order.
    static let all: [MarketRegion] = [
        MarketRegion(
            id: .global,
            indexes: [
                MarketIndex(symbol: "ACWI", name: "MSCI ACWI", currency: "USD", proxy: "iShares MSCI ACWI ETF"),
                MarketIndex(symbol: "URTH", name: "MSCI World", currency: "USD", proxy: "iShares MSCI World ETF"),
            ]
        ),
        MarketRegion(
            id: .northAmerica,
            indexes: [
                MarketIndex(symbol: "^GSPC", name: "S&P 500", currency: "USD"),
                MarketIndex(symbol: "^NDX", name: "Nasdaq-100", currency: "USD"),
                MarketIndex(symbol: "^RUT", name: "Russell 2000", currency: "USD"),
            ]
        ),
        MarketRegion(
            id: .europe,
            indexes: [
                MarketIndex(symbol: "^STOXX", name: "STOXX Europe 600", currency: "EUR")
            ]
        ),
        MarketRegion(
            id: .nordics,
            indexes: [
                MarketIndex(symbol: "^OMX", name: "OMX Stockholm 30", currency: "SEK"),
                MarketIndex(symbol: "XACT-NORDEN.ST", name: "Norden", currency: "SEK", proxy: "XACT Norden ETF"),
            ]
        ),
        MarketRegion(
            id: .asiaAndEmerging,
            indexes: [
                MarketIndex(
                    symbol: "EEM", name: "MSCI Emerging Markets", currency: "USD", proxy: "iShares MSCI EM ETF"),
                MarketIndex(symbol: "^N225", name: "Nikkei 225", currency: "JPY"),
                MarketIndex(symbol: "^NSEI", name: "Nifty 50", currency: "INR"),
            ]
        ),
    ]
}
