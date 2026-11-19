import SwiftUI

/// Farbwelt der Sterne – identisch zur Web-Version.
enum TilePalette: CaseIterable
{
    case blue
    case green
    case red
    case yellow
    case purple

    var base: Color
    {
        switch self
        {
        case .blue: Color(hex: 0x3D8BFF)
        case .green: Color(hex: 0x54C94A)
        case .red: Color(hex: 0xFF4D6D)
        case .yellow: Color(hex: 0xFFC22E)
        case .purple: Color(hex: 0xA35BFF)
        }
    }

    var light: Color
    {
        switch self
        {
        case .blue: Color(hex: 0x9CC8FF)
        case .green: Color(hex: 0xB0F396)
        case .red: Color(hex: 0xFFA4B6)
        case .yellow: Color(hex: 0xFFE694)
        case .purple: Color(hex: 0xDCBCFF)
        }
    }

    var dark: Color
    {
        switch self
        {
        case .blue: Color(hex: 0x1C53B8)
        case .green: Color(hex: 0x2A8A2B)
        case .red: Color(hex: 0xB81F3C)
        case .yellow: Color(hex: 0xC88700)
        case .purple: Color(hex: 0x6A26C9)
        }
    }

    /// Deutscher Name für VoiceOver.
    var accessibilityName: String
    {
        switch self
        {
        case .blue: "Blauer"
        case .green: "Grüner"
        case .red: "Roter"
        case .yellow: "Gelber"
        case .purple: "Lila"
        }
    }

    init(colorIndex: Int)
    {
        let all = Self.allCases
        self = all[abs(colorIndex) % all.count]
    }
}

/// Feste Werte für Layout und Animation.
enum Design
{
    static let horizontalPadding: CGFloat = 12
    static let spacing: CGFloat = 10
    static let boardCornerRadius: CGFloat = 22
    static let popCoolDown: Duration = .seconds(0.32)
    static let stageEndDelay: Duration = .seconds(0.45)
}

/// Dunkler Hintergrund mit zwei Farbschimmern – wie die Web-Version.
struct AppBackground: View
{
    var body: some View
    {
        ZStack
        {
            Color(hex: 0x0A0E28)
            RadialGradient(
                colors: [Color(hex: 0x24306B), .clear],
                center: UnitPoint(x: 0.5, y: -0.1),
                startRadius: 0,
                endRadius: 620
            )
            RadialGradient(
                colors: [Color(hex: 0x1B2A63), .clear],
                center: UnitPoint(x: 0.15, y: 1.1),
                startRadius: 0,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}
