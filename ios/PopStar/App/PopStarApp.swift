import SwiftUI

@main
struct PopStarApp: App
{
    var body: some Scene
    {
        WindowGroup
        {
            GameScreen()
                .preferredColorScheme(.dark)
        }
    }
}
