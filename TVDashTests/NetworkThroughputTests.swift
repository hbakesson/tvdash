import Testing

@testable import TVDash

@Suite("NetworkThroughput")
struct NetworkThroughputTests {
    @Test func sumsInterfacesPerSecond() {
        let old = ["en0": InterfaceCounters(bytesIn: 1000, bytesOut: 100), "en1": .init(bytesIn: 0, bytesOut: 0)]
        let new = ["en0": InterfaceCounters(bytesIn: 3000, bytesOut: 500), "en1": .init(bytesIn: 2000, bytesOut: 0)]

        let rate = NetworkThroughput(from: old, to: new, over: 2)

        #expect(rate.bytesInPerSecond == 2000)
        #expect(rate.bytesOutPerSecond == 200)
    }

    @Test func handlesCounterWrapAround() {
        let old = ["en0": InterfaceCounters(bytesIn: .max - 99, bytesOut: 0)]
        let new = ["en0": InterfaceCounters(bytesIn: 100, bytesOut: 0)]

        #expect(NetworkThroughput(from: old, to: new, over: 1).bytesInPerSecond == 200)
    }

    @Test func ignoresInterfacesThatJustAppeared() {
        let new = ["en0": InterfaceCounters(bytesIn: 5_000_000, bytesOut: 5_000_000)]

        #expect(NetworkThroughput(from: [:], to: new, over: 1) == .zero)
    }

    @Test func zeroWhenNoTimePassed() {
        let counters = ["en0": InterfaceCounters(bytesIn: 1, bytesOut: 1)]

        #expect(NetworkThroughput(from: counters, to: counters, over: 0) == .zero)
    }
}
