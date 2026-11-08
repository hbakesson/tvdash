import Foundation

/// Fetches index history from Yahoo Finance's public chart endpoint.
///
/// The endpoint is unofficial and needs no API key; see `docs/adr/0002-index-data-from-yahoo-finance.md`.
struct YahooFinanceService: IndexHistoryProviding {
    var session: URLSession = .shared

    func history(symbol: String, range: HistoryRange, interval: HistoryInterval) async throws -> IndexHistory {
        guard
            let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
            var components = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)")
        else {
            throw IndexHistoryError.invalidSymbol
        }

        var query = [URLQueryItem(name: "interval", value: Self.queryValue(for: interval))]
        switch range {
        case .yearToDate:
            query.append(URLQueryItem(name: "range", value: "ytd"))
        case .max:
            query.append(URLQueryItem(name: "range", value: "max"))
        case .since(let start):
            query.append(URLQueryItem(name: "period1", value: String(Int(start.timeIntervalSince1970))))
            query.append(URLQueryItem(name: "period2", value: String(Int(Date.now.timeIntervalSince1970))))
        }
        components.queryItems = query

        guard let url = components.url else { throw IndexHistoryError.invalidSymbol }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode), http.statusCode != 404 {
            throw IndexHistoryError.badStatus(http.statusCode)
        }
        return try await Self.decode(data)
    }

    private static func queryValue(for interval: HistoryInterval) -> String {
        switch interval {
        case .daily: "1d"
        case .weekly: "1wk"
        case .monthly: "1mo"
        }
    }

    /// Decodes on a background thread – ten years of daily data is a few hundred kilobytes of JSON.
    @concurrent
    private nonisolated static func decode(_ data: Data) async throws -> IndexHistory {
        try parse(data)
    }

    /// Converts a chart API response into an `IndexHistory`. Separate from networking so it can be unit tested.
    nonisolated static func parse(_ data: Data) throws -> IndexHistory {
        let response = try JSONDecoder().decode(ChartResponse.self, from: data)

        guard let result = response.chart.result?.first else {
            throw IndexHistoryError.noData(response.chart.error?.description ?? "Empty response")
        }

        let meta = result.meta
        let closes = result.indicators.quote.first?.close ?? []
        let points = zip(result.timestamp ?? [], closes).compactMap { timestamp, close -> IndexHistory.Point? in
            guard let close else { return nil }
            return IndexHistory.Point(date: Date(timeIntervalSince1970: timestamp), close: close)
        }

        guard let latest = meta.regularMarketPrice ?? points.last?.close else {
            throw IndexHistoryError.noData("No price for \(meta.symbol)")
        }
        guard let baseline = meta.chartPreviousClose ?? points.first?.close else {
            throw IndexHistoryError.noData("No baseline for \(meta.symbol)")
        }

        return IndexHistory(
            symbol: meta.symbol,
            name: meta.longName ?? meta.shortName ?? meta.symbol,
            currency: meta.currency ?? "",
            baseline: baseline,
            latest: latest,
            updatedAt: meta.regularMarketTime.map(Date.init(timeIntervalSince1970:)) ?? points.last?.date ?? .now,
            points: points
        )
    }
}

// MARK: - Response format

private nonisolated struct ChartResponse: Decodable {
    struct Chart: Decodable {
        let result: [Result]?
        let error: APIError?
    }

    struct APIError: Decodable {
        let code: String?
        let description: String?
    }

    struct Result: Decodable {
        let meta: Meta
        let timestamp: [TimeInterval]?
        let indicators: Indicators
    }

    struct Meta: Decodable {
        let symbol: String
        let currency: String?
        let longName: String?
        let shortName: String?
        let regularMarketPrice: Double?
        let regularMarketTime: TimeInterval?
        let chartPreviousClose: Double?
    }

    struct Indicators: Decodable {
        let quote: [Quote]
    }

    struct Quote: Decodable {
        let close: [Double?]
    }

    let chart: Chart
}
