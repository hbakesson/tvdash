import Foundation

@testable import TVDash

nonisolated let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

func makeSnapshot(
    at seconds: Double = 0,
    cores: [CoreTicks] = [],
    counters: [String: InterfaceCounters] = [:],
    memory: MemoryStats? = nil,
    bootDate: Date? = nil
) -> SystemSnapshot {
    SystemSnapshot(
        date: referenceDate.addingTimeInterval(seconds),
        memory: memory,
        cores: cores,
        process: nil,
        counters: counters,
        interfaces: [],
        bootDate: bootDate,
        thermalState: .nominal
    )
}
