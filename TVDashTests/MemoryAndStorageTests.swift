import Testing

@testable import TVDash

@Suite("MemoryStats and StorageStats")
struct MemoryAndStorageTests {
    @Test func availableMemoryIsFreePlusInactive() {
        let memory = MemoryStats(total: 1000, free: 100, active: 400, inactive: 150, wired: 300, compressed: 50)

        #expect(memory.available == 250)
        #expect(memory.used == 750)
        #expect(memory.usedFraction == 0.75)
    }

    @Test func availableMemoryNeverExceedsTotal() {
        let memory = MemoryStats(total: 100, free: 80, active: 0, inactive: 80, wired: 0, compressed: 0)

        #expect(memory.available == 100)
        #expect(memory.used == 0)
    }

    @Test func zeroTotalHasNoFraction() {
        #expect(MemoryStats(total: 0, free: 0, active: 0, inactive: 0, wired: 0, compressed: 0).usedFraction == 0)
    }

    @Test func storageSumsAppDirectories() {
        let storage = StorageStats(
            volumeTotal: 1000, volumeAvailable: 400, appBundle: 10, documents: 1, applicationSupport: 2,
            caches: 3, temporary: 4
        )

        #expect(storage.volumeUsed == 600)
        #expect(storage.usedFraction == 0.6)
        #expect(storage.appData == 10)
        #expect(storage.appTotal == 20)
    }
}
