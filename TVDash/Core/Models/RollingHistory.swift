import Foundation

/// The most recent values of a measurement, oldest first, for small charts.
nonisolated struct RollingHistory<Value: Sendable & Equatable>: Equatable, Sendable {
    struct Sample: Equatable, Sendable, Identifiable {
        var date: Date
        var value: Value

        var id: Date { date }
    }

    let capacity: Int
    private(set) var samples: [Sample] = []

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    mutating func append(_ value: Value, at date: Date) {
        samples.append(Sample(date: date, value: value))
        if samples.count > capacity {
            samples.removeFirst(samples.count - capacity)
        }
    }

    var latest: Value? { samples.last?.value }
}
