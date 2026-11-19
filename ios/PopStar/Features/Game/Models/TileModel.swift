import Foundation

/// Ein einzelner Stern auf dem Spielfeld.
struct TileModel: Identifiable, Equatable
{
    let id: Int
    /// Index in `TilePalette.allCases`
    let colorIndex: Int
    var row: Int
    var column: Int
}
