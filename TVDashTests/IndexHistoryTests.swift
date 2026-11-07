import Foundation
import Testing

@testable import TVDash

@Suite("IndexHistory")
struct IndexHistoryTests {
    private func history(baseline: Double, latest: Double, closes: [Double] = []) -> IndexHistory {
        IndexHistory(
            symbol: "^TEST",
            name: "Test",
            currency: "SEK",
            baseline: baseline,
            latest: latest,
            updatedAt: .now,
            points: closes.enumerated().map {
                .init(date: Date(timeIntervalSince1970: Double($0.offset)), close: $0.element)
            }
        )
    }

    @Test(arguments: [
        (2000.0, 2200.0, 200.0, 0.1),
        (2000.0, 1800.0, -200.0, -0.1),
        (0.0, 100.0, 100.0, 0.0),
    ])
    func yearToDateChange(baseline: Double, latest: Double, change: Double, fraction: Double) {
        let sut = history(baseline: baseline, latest: latest)

        #expect(sut.change == change)
        #expect(abs(sut.changeFraction - fraction) < 1e-9)
    }

    @Test func valueRangeIncludesBaselineAndPoints() {
        let sut = history(baseline: 100, latest: 120, closes: [90, 130, 110])

        #expect(sut.valueRange == 90...130)
    }
}
