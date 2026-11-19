import Foundation

/// Speichert und lädt den Rekord.
protocol ScoreStoring
{
    func loadBest() -> Int
    func saveBest(_ value: Int)
}

/// Standard-Implementierung über `UserDefaults`.
struct UserDefaultsScoreStore: ScoreStoring
{
    private let defaults: UserDefaults
    private let key = "popstar.best"

    init(defaults: UserDefaults = .standard)
    {
        self.defaults = defaults
    }

    func loadBest() -> Int
    {
        defaults.integer(forKey: key)
    }

    func saveBest(_ value: Int)
    {
        defaults.set(value, forKey: key)
    }
}
