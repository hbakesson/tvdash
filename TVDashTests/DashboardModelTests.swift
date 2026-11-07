import Testing
@testable import TVDash

@Suite("DashboardModel")
struct DashboardModelTests {
    @Test func startsWithoutSelection() {
        let model = DashboardModel()
        #expect(model.selectedTile == nil)
    }

    @Test func selectingTileUpdatesSelection() throws {
        let model = DashboardModel()
        let tile = try #require(model.tiles.first)

        model.select(tile)

        #expect(model.selectedTile == tile)
    }

    @Test func usesInjectedTiles() {
        let tiles = [DashboardTile(title: "Test", value: "1", systemImage: "star")]
        let model = DashboardModel(tiles: tiles)
        #expect(model.tiles == tiles)
    }
}
