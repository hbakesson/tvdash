import Foundation

extension UInt64 {
    /// RAM sizes, binary units: `3.2 GB`.
    var memoryText: String {
        Int64(clamping: self).formatted(.byteCount(style: .memory))
    }

    /// Disk sizes, decimal units like Finder: `32 GB`.
    var fileText: String {
        Int64(clamping: self).formatted(.byteCount(style: .file))
    }
}

extension Double {
    /// `0.62` → `62 %`.
    var percentText: String {
        formatted(.percent.precision(.fractionLength(0)))
    }

    /// Bits per second: `94.3 Mbit/s`.
    var dataRateText: String {
        DataRateFormat().format(self)
    }
}

extension Range<Date> {
    /// `3 days, 4 hours, 12 minutes`, without seconds so it does not flicker.
    var durationText: String {
        formatted(.components(style: .wide, fields: [.day, .hour, .minute]))
    }

    /// `3 d 4 h`, for tiles.
    var shortDurationText: String {
        formatted(.components(style: .abbreviated, fields: [.day, .hour, .minute]))
    }
}
