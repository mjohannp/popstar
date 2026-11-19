import Foundation

/// Spielregeln von PopStar: Gruppen finden, Punkte vergeben, Steine fallen
/// lassen, Spalten zusammenziehen und Stages abschließen.
///
/// Die Feldgröße ist frei wählbar (`rows` × `columns`), alle Regeln arbeiten
/// dimensionsunabhängig. Die Engine enthält keinerlei UI-Code und ist dadurch
/// vollständig unit-testbar. Die Views beobachten den Zustand über `@Observable`.
@MainActor
@Observable
final class GameEngine
{
    // MARK: - Konfiguration

    enum Config
    {
        static let colorCount = 5
        /// Bis zu so vielen restlichen Steinen gibt es einen Stage-Bonus.
        static let maximumRemainingForBonus = 10
        static let baseBonus = 2000
        static let bonusPenaltyPerSquaredTile = 20
    }

    // MARK: - Typen

    enum Phase: Equatable
    {
        case intro
        case playing
        case stageFinished(StageSummary)
    }

    struct StageSummary: Equatable
    {
        let stage: Int
        let remaining: Int
        let bonus: Int
        let totalScore: Int
        let isNewRecord: Bool
    }

    enum TapOutcome: Equatable
    {
        case selected(groupSize: Int)
        case popped(groupSize: Int, points: Int)
        case rejected
    }

    // MARK: - Feldmaße

    /// Anzahl Reihen (von oben nach unten).
    let rows: Int
    /// Anzahl Spalten (von links nach rechts).
    let columns: Int

    // MARK: - Zustand

    private(set) var tiles: [TileModel] = []
    private(set) var selectedTileIDs: Set<TileModel.ID> = []
    private(set) var score = 0
    private(set) var stage = 1
    private(set) var bestScore: Int
    private(set) var phase: Phase = .intro

    /// Zufallsquelle – für Tests durch einen deterministischen Generator ersetzbar.
    var rng: any RandomNumberGenerator = SystemRandomNumberGenerator()

    private var grid: [[TileModel.ID?]] = []
    private var nextTileID = 0
    private let scoreStore: any ScoreStoring

    // MARK: - Init

    /// - Parameters:
    ///   - rows: Anzahl Reihen (Standard 10).
    ///   - columns: Anzahl Spalten (Standard 10).
    init(
        rows: Int = 10,
        columns: Int = 10,
        scoreStore: any ScoreStoring = UserDefaultsScoreStore(),
        rng: (any RandomNumberGenerator)? = nil
    )
    {
        self.rows = max(2, rows)
        self.columns = max(2, columns)
        self.scoreStore = scoreStore
        bestScore = scoreStore.loadBest()
        if let rng
        {
            self.rng = rng
        }
        buildStage()
    }

    // MARK: - Spielzüge

    /// Verarbeitet einen Tipp auf ein Feld: Baut die Auswahl auf oder lässt
    /// eine bereits ausgewählte Gruppe platzen.
    func tap(atRow row: Int, column: Int) -> TapOutcome?
    {
        guard phase == .playing, let tile = tile(atRow: row, column: column) else { return nil }

        let group = connectedGroup(containing: tile)

        if group.count < 2
        {
            clearSelection()
            return .rejected
        }

        if selectedTileIDs.contains(tile.id)
        {
            popGroup(group)
            return .popped(groupSize: group.count, points: Self.points(forGroupSize: group.count))
        }

        select(group)
        return .selected(groupSize: group.count)
    }

    /// Prüft nach einem Zug, ob die Stage beendet ist, und vergibt dann den
    /// Rest-Bonus. Wird von der View verzögert aufgerufen, damit die
    /// Fall-Animation durchlaufen kann.
    ///
    /// - Returns: `true`, wenn die Stage beendet wurde.
    @discardableResult
    func evaluateStageEnd() -> Bool
    {
        guard phase == .playing, !hasMoves() else { return false }

        let remaining = tiles.count
        let bonus = Self.stageBonus(forRemaining: remaining)
        score += bonus
        let isNewRecord = score > bestScore
        if isNewRecord
        {
            bestScore = score
            scoreStore.saveBest(score)
        }

        phase = .stageFinished(StageSummary(
            stage: stage,
            remaining: remaining,
            bonus: bonus,
            totalScore: score,
            isNewRecord: isNewRecord
        ))
        return true
    }

    /// Startet die nächste Stage mit einem neuen Feld.
    func startNextStage()
    {
        stage += 1
        buildStage()
        phase = .playing
    }

    /// Verlässt das Intro und zeigt das bereits aufgebaute Feld.
    func startGame()
    {
        phase = .playing
    }

    /// Setzt Punkte und Stage zurück und erzeugt ein neues Feld.
    func restart()
    {
        score = 0
        stage = 1
        buildStage()
        phase = .playing
    }

    // MARK: - Abfragen

    /// Liefert den Stein an einer Position, falls vorhanden.
    func tile(atRow row: Int, column: Int) -> TileModel?
    {
        guard grid.indices.contains(row), grid[row].indices.contains(column),
              let id = grid[row][column]
        else { return nil }
        return tiles.first { $0.id == id }
    }

    /// Existiert mindestens eine Gruppe mit zwei oder mehr gleichen Farben?
    func hasMoves() -> Bool
    {
        Self.hasMoves(in: colorMatrix())
    }

    /// Punkte für eine Gruppe: 5 × Blöcke².
    static func points(forGroupSize groupSize: Int) -> Int
    {
        5 * groupSize * groupSize
    }

    /// Rest-Bonus für eine Stage: 2000 − 20 × Blöcke², sofern höchstens
    /// 10 Blöcke übrig sind.
    static func stageBonus(forRemaining remaining: Int) -> Int
    {
        guard remaining <= Config.maximumRemainingForBonus else { return 0 }
        let penalty = Config.bonusPenaltyPerSquaredTile * remaining * remaining
        return max(0, Config.baseBonus - penalty)
    }

    // MARK: - Test- und Preview-Hilfen

    /// Baut das Feld direkt aus einer Farbmatrix auf (Reihen von oben nach unten).
    func load(colors: [[Int]])
    {
        rebuild(from: colors)
    }

    // MARK: - Spiellogik

    private func select(_ group: [TileModel])
    {
        selectedTileIDs = Set(group.map(\.id))
    }

    private func clearSelection()
    {
        selectedTileIDs = []
    }

    private func popGroup(_ group: [TileModel])
    {
        score += Self.points(forGroupSize: group.count)

        let poppedIDs = Set(group.map(\.id))
        for tile in group
        {
            grid[tile.row][tile.column] = nil
        }
        tiles.removeAll { poppedIDs.contains($0.id) }
        clearSelection()

        applyGravity()
        collapseColumns()
        syncTilesWithGrid()
    }

    /// Alle direkt verbundenen Steine derselben Farbe (4-Nachbarschaft).
    private func connectedGroup(containing start: TileModel) -> [TileModel]
    {
        let colorsByID = Dictionary(uniqueKeysWithValues: tiles.map { ($0.id, $0.colorIndex) })
        var visited: Set<TileModel.ID> = [start.id]
        var stack: [TileModel] = [start]
        var group: [TileModel] = []

        while let current = stack.popLast()
        {
            group.append(current)
            for neighbor in neighborPositions(of: current)
            {
                guard let id = grid[neighbor.row][neighbor.column],
                      !visited.contains(id),
                      colorsByID[id] == start.colorIndex
                else { continue }
                visited.insert(id)
                if let neighborTile = tile(atRow: neighbor.row, column: neighbor.column)
                {
                    stack.append(neighborTile)
                }
            }
        }
        return group
    }

    private func neighborPositions(of tile: TileModel) -> [(row: Int, column: Int)]
    {
        var positions: [(row: Int, column: Int)] = []
        if tile.row > 0 { positions.append((tile.row - 1, tile.column)) }
        if tile.row < rows - 1 { positions.append((tile.row + 1, tile.column)) }
        if tile.column > 0 { positions.append((tile.row, tile.column - 1)) }
        if tile.column < columns - 1 { positions.append((tile.row, tile.column + 1)) }
        return positions
    }

    /// Lässt alle Steine in einer Spalte nach unten rutschen.
    private func applyGravity()
    {
        for column in 0..<columns
        {
            var writeRow = rows - 1
            for row in stride(from: rows - 1, through: 0, by: -1)
            {
                guard let id = grid[row][column] else { continue }
                if writeRow != row
                {
                    grid[writeRow][column] = id
                    grid[row][column] = nil
                }
                writeRow -= 1
            }
        }
    }

    /// Schließt leere Spalten und rückt alle Spalten nach links zusammen.
    private func collapseColumns()
    {
        var targetColumn = 0
        for column in 0..<columns
        {
            let isEmpty = (0..<rows).allSatisfy { grid[$0][column] == nil }
            if isEmpty { continue }

            if targetColumn != column
            {
                for row in 0..<rows
                {
                    grid[row][targetColumn] = grid[row][column]
                    grid[row][column] = nil
                }
            }
            targetColumn += 1
        }
    }

    /// Überträgt die Positionen aus dem Raster zurück in die Steine.
    private func syncTilesWithGrid()
    {
        var tilesByID = Dictionary(uniqueKeysWithValues: tiles.map { ($0.id, $0) })
        for row in 0..<rows
        {
            for column in 0..<columns
            {
                guard let id = grid[row][column], var tile = tilesByID[id] else { continue }
                tile.row = row
                tile.column = column
                tilesByID[id] = tile
            }
        }
        tiles = tilesByID.values.sorted
        {
            if $0.column != $1.column { return $0.column < $1.column }
            return $0.row < $1.row
        }
    }

    private func colorMatrix() -> [[Int]]
    {
        let colorsByID = Dictionary(uniqueKeysWithValues: tiles.map { ($0.id, $0.colorIndex) })
        var colors = Array(repeating: Array(repeating: -1, count: columns), count: rows)
        for row in 0..<rows
        {
            for column in 0..<columns
            {
                if let id = grid[row][column]
                {
                    colors[row][column] = colorsByID[id] ?? -1
                }
            }
        }
        return colors
    }

    private func buildStage()
    {
        var colors: [[Int]]
        repeat
        {
            colors = (0..<rows).map { _ in
                (0..<columns).map { _ in Int(rng.next() % UInt64(Config.colorCount)) }
            }
        } while !Self.hasMoves(in: colors)

        rebuild(from: colors)
    }

    private func rebuild(from colors: [[Int]])
    {
        var newTiles: [TileModel] = []
        var newGrid = Array(repeating: Array(repeating: Optional<TileModel.ID>.none, count: columns), count: rows)

        for row in 0..<rows
        {
            for column in 0..<columns
            {
                let tile = TileModel(id: nextTileID, colorIndex: colors[row][column], row: row, column: column)
                nextTileID += 1
                newTiles.append(tile)
                newGrid[row][column] = tile.id
            }
        }
        tiles = newTiles
        grid = newGrid
        selectedTileIDs = []
    }

    // MARK: - Statische Regeln

    /// Existiert in einer Farbmatrix mindestens ein horizontales oder
    /// vertikales Paar gleicher Farben? Leere Felder (`-1`) zählen nicht.
    static func hasMoves(in colors: [[Int]]) -> Bool
    {
        for row in 0..<colors.count
        {
            for column in 0..<colors[row].count
            {
                let color = colors[row][column]
                if color < 0 { continue }
                if column + 1 < colors[row].count, colors[row][column + 1] == color { return true }
                if row + 1 < colors.count, colors[row + 1][column] == color { return true }
            }
        }
        return false
    }
}
