import CoreGraphics
import Foundation

/// Rechnet die Kachelmaße für ein `rows × columns`-Feld aus dem verfügbaren
/// Platz her.
///
/// Zellgröße, Abstand und Außenabstand ergeben sich aus beiden Dimensionen:
/// Die Zelle ist so groß wie es gleichzeitig in die Breite **und** die Höhe
/// passt, damit auch rechteckige Felder (z. B. 8×12) ohne Verzerrung oder
/// Überlauf skaliert werden. Die Ränder sind symmetrisch: Außenabstand =
/// Innenabstand zwischen zwei Kacheln.
struct BoardLayout
{
    let cellSize: CGFloat
    let gap: CGFloat
    /// Außenabstand (= `gap * 2`), damit Innen- und Außenabstand gleich sind.
    let pad: CGFloat
    let rows: Int
    let columns: Int

    var boardWidth: CGFloat { CGFloat(columns) * cellSize + gap * 2 }
    var boardHeight: CGFloat { CGFloat(rows) * cellSize + gap * 2 }
    var tileSize: CGFloat { cellSize - gap * 2 }

    /// - Parameters:
    ///   - availableWidth: Verfügbare Breite für das komplette Feld.
    ///   - availableHeight: Verfügbare Höhe für das komplette Feld.
    init(availableWidth: CGFloat, availableHeight: CGFloat, rows: Int, columns: Int)
    {
        self.rows = max(1, rows)
        self.columns = max(1, columns)

        // Gap zuerst aus einer groben Schätzung ableiten, dann die Zellgröße
        // exakt auf den verbleibenden Platz rechnen.
        let estimate = min(
            availableWidth / CGFloat(self.columns),
            availableHeight / CGFloat(self.rows)
        )
        gap = max(2, (estimate * 0.075).rounded())
        pad = gap * 2

        let widthCell = ((availableWidth - pad * 2) / CGFloat(self.columns)).rounded(.down)
        let heightCell = ((availableHeight - pad * 2) / CGFloat(self.rows)).rounded(.down)
        cellSize = max(4, min(widthCell, heightCell))
    }

    /// Mittelpunkt einer Kachel innerhalb des Spielfelds.
    func position(of tile: TileModel) -> CGPoint
    {
        CGPoint(
            x: pad + CGFloat(tile.column) * cellSize + tileSize / 2,
            y: pad + CGFloat(tile.row) * cellSize + tileSize / 2
        )
    }
}
