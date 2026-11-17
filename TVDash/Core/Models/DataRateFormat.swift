import Foundation

/// Formats network speeds in bits per second with a decimal prefix: `940 Mbit/s`.
nonisolated struct DataRateFormat: FormatStyle {
    var locale: Locale = .current

    func format(_ bitsPerSecond: Double) -> String {
        let units: [(Double, String)] = [(1e9, "Gbit/s"), (1e6, "Mbit/s"), (1e3, "kbit/s")]
        let (divisor, unit) = units.first { bitsPerSecond >= $0.0 } ?? (1, "bit/s")
        let value = bitsPerSecond / divisor
        let digits = value < 10 && divisor > 1 ? 1 : 0
        let number = value.formatted(.number.precision(.fractionLength(digits)).locale(locale))
        return "\(number) \(unit)"
    }

    func locale(_ locale: Locale) -> DataRateFormat {
        DataRateFormat(locale: locale)
    }
}

extension FormatStyle where Self == DataRateFormat {
    nonisolated static var dataRate: DataRateFormat { DataRateFormat() }
}
