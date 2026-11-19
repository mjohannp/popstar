import SwiftUI

/// Statuszeile unter dem Spielfeld mit Rest-Anzeige bzw. Auswahl-Info.
enum FooterInfo: Equatable
{
    case remaining(Int)
    case selection(groupSize: Int, points: Int)
}

struct FooterView: View
{
    let info: FooterInfo
    let isSoundOn: Bool
    let onToggleSound: () -> Void
    let onRestart: () -> Void

    var body: some View
    {
        HStack(spacing: 10)
        {
            infoText
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x93A2D8))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onToggleSound)
            {
                Image(systemName: isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .buttonStyle(IconButtonStyle())
            .accessibilityLabel(isSoundOn ? "Ton ausschalten" : "Ton einschalten")

            Button(action: onRestart)
            {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(IconButtonStyle())
            .accessibilityLabel("Neustart")
        }
    }

    @ViewBuilder
    private var infoText: some View
    {
        switch info
        {
        case .remaining(let count):
            Text("\(count.formatted()) Blöcke übrig")
        case .selection(let groupSize, let points):
            Text("\(groupSize) Sterne · ")
                + Text("+\(points) Punkte").foregroundStyle(Color(hex: 0xFFD75E))
                + Text(" – erneut tippen")
        }
    }
}

/// Runder dunkler Icon-Button.
struct IconButtonStyle: ButtonStyle
{
    func makeBody(configuration: Configuration) -> some View
    {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color(hex: 0xDBE4FF))
            .frame(width: 42, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x222C68), Color(hex: 0x161E4C)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
