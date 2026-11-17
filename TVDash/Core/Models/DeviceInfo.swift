import Foundation

/// Facts about the device and software that do not change while the app runs.
nonisolated struct DeviceInfo: Equatable, Sendable {
    var name: String
    /// Hardware identifier such as `AppleTV14,1`.
    var modelIdentifier: String
    var isSimulator: Bool
    var systemName: String
    var systemVersion: String
    /// OS build number such as `23J582`.
    var systemBuild: String
    /// Darwin kernel release such as `25.0.0`.
    var kernelVersion: String
    var processorCount: Int
    var activeProcessorCount: Int
    var physicalMemory: UInt64
    var appVersion: String
    var appBuild: String
    var launchDate: Date

    /// Marketing name for the hardware, falling back to the identifier for models we do not know yet.
    var modelName: String {
        Self.modelNames[modelIdentifier] ?? modelIdentifier
    }

    static let modelNames: [String: String] = [
        "AppleTV5,3": "Apple TV HD",
        "AppleTV6,2": "Apple TV 4K",
        "AppleTV11,1": "Apple TV 4K (2nd generation)",
        "AppleTV14,1": "Apple TV 4K (3rd generation)",
        "AppleTV18,1": "Apple TV 4K (4th generation)",
    ]
}
