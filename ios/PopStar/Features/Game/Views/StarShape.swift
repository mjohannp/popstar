import SwiftUI

/// Fünfeckiger Stern als Pfad – Pendant zum `clip-path` der Web-Version.
struct StarShape: Shape
{
    /// Verhältnis des inneren zum äußeren Radius.
    var innerRatio: CGFloat = 0.45

    func path(in rect: CGRect) -> Path
    {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()

        for index in 0..<10
        {
            let angle = CGFloat.pi / 5 * CGFloat(index) - .pi / 2
            let distance = index.isMultiple(of: 2) ? radius : radius * innerRatio
            let point = CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )
            if index == 0
            {
                path.move(to: point)
            }
            else
            {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// Kleines Wackeln für abgelehnte Tipps (Einzelstein).
struct ShakeEffect: GeometryEffect
{
    var travel: CGFloat = 5
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform
    {
        let offset = travel * sin(animatableData * .pi * shakesPerUnit * 2)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
