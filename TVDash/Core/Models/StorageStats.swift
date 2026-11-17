import Foundation

/// Disk space on the device's data volume and how much of it this app uses.
///
/// tvOS has no API for listing other installed apps or their sizes.
nonisolated struct StorageStats: Equatable, Sendable {
    var volumeTotal: UInt64
    var volumeAvailable: UInt64
    /// The app itself (code and resources).
    var appBundle: UInt64
    var documents: UInt64
    var applicationSupport: UInt64
    /// Cache files tvOS may delete at any time.
    var caches: UInt64
    var temporary: UInt64

    var volumeUsed: UInt64 { volumeTotal - min(volumeAvailable, volumeTotal) }

    var usedFraction: Double {
        volumeTotal == 0 ? 0 : Double(volumeUsed) / Double(volumeTotal)
    }

    /// Everything the app stores outside its bundle.
    var appData: UInt64 { documents + applicationSupport + caches + temporary }

    var appTotal: UInt64 { appBundle + appData }
}
