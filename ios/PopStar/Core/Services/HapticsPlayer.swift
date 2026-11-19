import UIKit

enum HapticFeedback
{
    case light
    case medium
    case success
}

@MainActor
protocol HapticsPlaying
{
    func fire(_ feedback: HapticFeedback)
}

/// Haptisches Feedback für Auswahl, Platzen und Stage-Abschluss.
@MainActor
final class HapticsPlayer: HapticsPlaying
{
    private let selectGenerator = UIImpactFeedbackGenerator(style: .light)
    private let popGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    func fire(_ feedback: HapticFeedback)
    {
        switch feedback
        {
        case .light:
            selectGenerator.impactOccurred(intensity: 0.6)
        case .medium:
            popGenerator.impactOccurred()
        case .success:
            notificationGenerator.notificationOccurred(.success)
        }
    }
}
