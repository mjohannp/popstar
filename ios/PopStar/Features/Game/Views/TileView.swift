import SwiftUI

/// Eine einzelne Kachel: abgerundetes Quadrat mit Farbverlauf, Glanzlicht und Stern.
struct TileView: View
{
    let tile: TileModel
    let size: CGFloat
    let isSelected: Bool
    let isShaking: Bool

    private var palette: TilePalette { TilePalette(colorIndex: tile.colorIndex) }

    var body: some View
    {
        ZStack
        {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.light, palette.base, palette.dark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(gloss)
                .overlay(topHighlight)

            StarShape()
                .fill(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.62)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(size * 0.18)
                .shadow(color: .black.opacity(0.28), radius: 1, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.35), radius: 3, y: 3)
        .scaleEffect(isSelected ? 1.07 : 1)
        .brightness(isSelected ? 0.12 : 0)
        .overlay(selectionRing)
        .modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(palette.accessibilityName) Stern, Reihe \(tile.row + 1), Spalte \(tile.column + 1)")
        .accessibilityHint(isSelected ? "Tippe erneut, um die Gruppe platzen zu lassen" : "Tippe, um die Gruppe auszuwählen")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var gloss: some View
    {
        LinearGradient(
            colors: [.white.opacity(0.5), .white.opacity(0)],
            startPoint: .topLeading,
            endPoint: .center
        )
        .clipShape(
            Ellipse()
                .scale(x: 0.72, y: 0.4, anchor: .leading)
                .offset(y: -size * 0.18)
        )
        .allowsHitTesting(false)
    }

    private var topHighlight: some View
    {
        RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
            .strokeBorder(.white.opacity(0.5), lineWidth: 1)
            .mask(
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.55)
                )
            )
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var selectionRing: some View
    {
        if isSelected
        {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .strokeBorder(.white.opacity(0.85), lineWidth: 2)
                .shadow(color: .white.opacity(0.5), radius: 6)
                .allowsHitTesting(false)
        }
    }
}

#Preview("Alle Farben")
{
    HStack(spacing: 8)
    {
        ForEach(0..<5, id: \.self) { index in
            TileView(tile: TileModel(id: index, colorIndex: index, row: 0, column: index), size: 44, isSelected: false, isShaking: false)
        }
    }
    .padding(24)
    .background(Color(hex: 0x0A0E28))
}

#Preview("Ausgewählt")
{
    TileView(tile: TileModel(id: 0, colorIndex: 0, row: 0, column: 0), size: 44, isSelected: true, isShaking: false)
        .padding(24)
        .background(Color(hex: 0x0A0E28))
}
