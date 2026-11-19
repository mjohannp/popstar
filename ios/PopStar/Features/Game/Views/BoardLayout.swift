import CoreGraphics
import Foundation

/// Rechnet Pixelmaße für das 10×10-Feld aus einer verfügbaren Kantenlänge her.
///
/// Spiegelt die Maße der Web-Version: Die Kacheln sind kleiner als die Zelle,
/// damit außen derselbe Abstand bleibt wie zwischen den Kacheln.
struct BoardLayout
{
    let cellSize: CGFloat
    let gap: CGFloat
    let pad: CGFloat

    var boardSideLength: CGFloat { CGFloat(GameEngine.Config.columns) * cellSize + gap * 2 }
    var tileSize: CGFloat { cellSize - gap * 2 }

    init(sideLength: CGFloat)
    {
        cellSize = max(24, (sideLength / 10.2).rounded(.down))
        gap = max(2, (cellSize * 0.075).rounded())
        pad = gap * 2
    }

    /// Mittelpunkt einer Kachel innerhalb des Spielfelds.
    func position(of tile: TileModel) -> CGPoint
    {
        CGPoint(
            x: pad + CGFloat(tile.column) * cellSize + cellSize / 2,
            y: pad + CGFloat(tile.row) * cellSize + cellSize / 2
        )
    }
}
