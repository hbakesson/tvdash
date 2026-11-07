import Observation

/// State and logic for the dashboard screen.
///
/// Views read from this model and call its methods; they never mutate data directly.
/// Runs on the main actor (the project's default isolation).
@Observable
final class DashboardModel {
    private(set) var tiles: [DashboardTile]
    var selectedTileID: DashboardTile.ID?

    init(tiles: [DashboardTile] = DashboardTile.samples) {
        self.tiles = tiles
    }

    var selectedTile: DashboardTile? {
        tiles.first { $0.id == selectedTileID }
    }

    func select(_ tile: DashboardTile) {
        selectedTileID = tile.id
    }
}
