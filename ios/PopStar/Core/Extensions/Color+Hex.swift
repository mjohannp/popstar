import SwiftUI

extension Color
{
    /// Baut eine Farbe aus einem Hex-Wert wie `0x3D8BFF`.
    init(hex: UInt)
    {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
