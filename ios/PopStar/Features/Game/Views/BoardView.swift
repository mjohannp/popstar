import SwiftUI

/// Spielfeld-Panel mit allen animierten Steinen.
struct BoardView: View
{
    let engine: GameEngine
    let sideLength: CGFloat
    let shakingTileID: TileModel.ID?
    let onTap: (TileModel) -> Void

    var body: some View
    {
        panel(BoardLayout(sideLength: sideLength))
    }

    private func panel(_ layout: BoardLayout) -> some View
    {
        ZStack
        {
            RoundedRectangle(cornerRadius: Design.boardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1A2354), Color(hex: 0x101740)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Design.boardCornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.055), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.55), radius: 24, y: 18)

            ForEach(engine.tiles) { tile in
                TileView(
                    tile: tile,
                    size: layout.tileSize,
                    isSelected: engine.selectedTileIDs.contains(tile.id),
                    isShaking: shakingTileID == tile.id
                )
                .position(layout.position(of: tile))
                .transition(.scale(scale: 1.5).combined(with: .opacity))
                .onTapGesture { onTap(tile) }
            }
        }
        .frame(width: layout.boardSideLength, height: layout.boardSideLength)
    }
}
