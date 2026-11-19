import SwiftUI

/// Eine Zeile in der Overlay-Karte (Beschriftung links, Wert rechts).
struct OverlayRow: Identifiable
{
    let label: String
    let value: String
    var isHighlighted: Bool = false

    var id: String { label }
}

/// Dunkle Karte über dem Spielfeld für Intro und Stage-Abschluss.
struct OverlayView: View
{
    let title: String
    let message: String
    let rows: [OverlayRow]
    let buttonTitle: String
    let action: () -> Void

    var body: some View
    {
        ZStack
        {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            card
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private var card: some View
    {
        VStack(spacing: 14)
        {
            Text(title)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: 0xFFD75E)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 1, y: 2)

            Text(message)
                .font(.system(size: 13.5, design: .rounded))
                .foregroundStyle(Color(hex: 0xAAB6E8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 6)
            {
                ForEach(rows) { row in
                    rowView(row)
                }
            }

            Button(action: action)
            {
                Text(buttonTitle)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x22180A))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xFFE07A), Color(hex: 0xFFB92E)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: Color(hex: 0xFFB428).opacity(0.55), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x232E6E), Color(hex: 0x131A45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 30, y: 16)
        .padding(24)
    }

    private func rowView(_ row: OverlayRow) -> some View
    {
        HStack
        {
            Text(row.label)
            Spacer()
            Text(row.value)
                .foregroundStyle(row.isHighlighted ? Color(hex: 0xFFD75E) : Color(hex: 0xFFD75E).opacity(0.9))
        }
        .font(.system(size: 13.5, weight: .bold, design: .rounded))
        .foregroundStyle(Color(hex: 0xC8D2F7))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.05))
        )
    }
}
