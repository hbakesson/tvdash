import Foundation
import Testing

@testable import TVDash

@Suite("Formatting")
struct FormattingTests {
    @Test(arguments: [
        (0.0, "0 bit/s"),
        (950.0, "950 bit/s"),
        (1_500.0, "1.5 kbit/s"),
        (94_300_000.0, "94 Mbit/s"),
        (9_430_000.0, "9.4 Mbit/s"),
        (1_200_000_000.0, "1.2 Gbit/s"),
    ])
    func formatsDataRates(bitsPerSecond: Double, expected: String) {
        let style = DataRateFormat(locale: Locale(identifier: "en_US"))

        #expect(style.format(bitsPerSecond) == expected)
    }

    @Test func bitsPerSecondFromBytesAndDuration() {
        #expect(SpeedTestResult.bitsPerSecond(bytes: 1_000_000, duration: .seconds(2)) == 4_000_000)
        #expect(SpeedTestResult.bitsPerSecond(bytes: 1_000_000, duration: .zero) == 0)
    }

    @Test func modelNamesFallBackToIdentifier() {
        var info = PreviewMetrics().deviceInfo()
        #expect(info.modelName == "Apple TV 4K (4th generation)")

        info.modelIdentifier = "AppleTV99,9"
        #expect(info.modelName == "AppleTV99,9")
    }
}

@Suite("RollingHistory")
struct RollingHistoryTests {
    @Test func keepsOnlyTheNewestValues() {
        var history = RollingHistory<Double>(capacity: 3)

        for value in 1...5 {
            history.append(Double(value), at: referenceDate.addingTimeInterval(Double(value)))
        }

        #expect(history.samples.map(\.value) == [3, 4, 5])
        #expect(history.latest == 5)
    }
}
