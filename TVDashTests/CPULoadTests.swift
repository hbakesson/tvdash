import Testing

@testable import TVDash

@Suite("CPULoad")
struct CPULoadTests {
    @Test func splitsTicksIntoUserAndSystem() {
        let old = CoreTicks(user: 100, system: 50, idle: 1000, nice: 0)
        let new = CoreTicks(user: 150, system: 75, idle: 1100, nice: 25)

        let load = CPULoad(from: old, to: new)

        #expect(load.user == 0.375)
        #expect(load.system == 0.125)
        #expect(load.total == 0.5)
    }

    @Test func handlesCounterWrapAround() {
        let old = CoreTicks(user: .max - 9, system: 0, idle: .max - 9, nice: 0)
        let new = CoreTicks(user: 10, system: 0, idle: 10, nice: 0)

        let load = CPULoad(from: old, to: new)

        #expect(load.user == 0.5)
    }

    @Test func idleWhenNoTicksPassed() {
        let ticks = CoreTicks(user: 1, system: 2, idle: 3, nice: 4)

        #expect(CPULoad(from: ticks, to: ticks) == .idle)
    }

    @Test func averagesCores() {
        let loads = [CPULoad(user: 1, system: 0), CPULoad(user: 0, system: 0.5)]

        let average = CPULoad.average(of: loads)

        #expect(average.user == 0.5)
        #expect(average.system == 0.25)
        #expect(CPULoad.average(of: []) == .idle)
    }
}
