import Foundation
import Testing

@testable import TVDash

@Suite("YahooFinanceService.parse")
struct YahooFinanceServiceTests {
    private let sample = Data(
        """
        {"chart":{"result":[{
          "meta":{"symbol":"^OMX","currency":"SEK","longName":"OMX Stockholm 30 Index",
                  "regularMarketPrice":3267.88,"regularMarketTime":1793982900,"chartPreviousClose":2882.97},
          "timestamp":[1767340800,1767600000,1767686400],
          "indicators":{"quote":[{"close":[2881.19,null,2901.5]}]}
        }],"error":null}}
        """.utf8
    )

    @Test func parsesMetadata() throws {
        let history = try YahooFinanceService.parse(sample)

        #expect(history.symbol == "^OMX")
        #expect(history.name == "OMX Stockholm 30 Index")
        #expect(history.currency == "SEK")
        #expect(history.latest == 3267.88)
        #expect(history.baseline == 2882.97)
        #expect(history.updatedAt == Date(timeIntervalSince1970: 1_793_982_900))
    }

    @Test func skipsMissingCloses() throws {
        let history = try YahooFinanceService.parse(sample)

        #expect(history.points.map(\.close) == [2881.19, 2901.5])
        #expect(history.points.first?.date == Date(timeIntervalSince1970: 1_767_340_800))
    }

    @Test func throwsOnApiError() {
        let notFound = Data(
            #"{"chart":{"result":null,"error":{"code":"Not Found","description":"No data found"}}}"#.utf8
        )

        #expect(throws: IndexHistoryError.noData("No data found")) {
            try YahooFinanceService.parse(notFound)
        }
    }
}
