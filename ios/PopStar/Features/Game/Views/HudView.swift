import SwiftUI

/// Kopfzeile mit Stage, Punkten und Rekord.
struct HudView: View
{
    let stage: Int
    let score: Int
    let bestScore: Int

    var body: some View
    {
        HStack(spacing: 8)
        {
            statCard(title: "Stage", value: String(stage), isHighlighted: false)
            scoreCard
            statCard(title: "Rekord", value: bestScore.formatted(), isHighlighted: false)
        }
    }

    private func statCard(title: String, value: String, isHighlighted: Bool) -> some View
    {
        VStack(spacing: 2)
        {
            Text(title)
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.6)
                .foregroundStyle(Color(hex: 0x8494CC))
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1E2860), Color(hex: 0x141C48)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var scoreCard: some View
    {
        VStack(spacing: 2)
        {
            Text("Punkte")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.6)
                .foregroundStyle(Color(hex: 0x8494CC))
            Text(score.formatted())
                .font(.system(size: 26, weight: .black, design: .rounded))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Color(hex: 0xFFD75E))
                .shadow(color: Color(hex: 0xFFC83C).opacity(0.45), radius: 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2B2F7A), Color(hex: 0x1A1F55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(hex: 0xFFD75E).opacity(0.22), lineWidth: 1)
        )
        .animation(.snappy, value: score)
        .accessibilityElement(children: .combine)
    }
}
