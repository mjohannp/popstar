import XCTest
@testable import PopStar

/// Zufallsquelle mit festem Seed für deterministische Felder in Tests.
struct SeededGenerator: RandomNumberGenerator
{
    private var state: UInt64

    init(seed: UInt64)
    {
        state = seed
    }

    mutating func next() -> UInt64
    {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}

/// Mock für den Rekord-Speicher.
final class ScoreStoreMock: ScoreStoring
{
    private let storedBest: Int
    private(set) var savedValues: [Int] = []

    init(storedBest: Int = 0)
    {
        self.storedBest = storedBest
    }

    func loadBest() -> Int
    {
        storedBest
    }

    func saveBest(_ value: Int)
    {
        savedValues.append(value)
    }
}

@MainActor
final class GameEngineTests: XCTestCase
{
    private let rowCount = 10
    private let columnCount = 10

    // MARK: - Hilfsfunktionen

    private func makeEngine(
        colors: [[Int]]? = nil,
        storedBest: Int = 0,
        seed: UInt64? = nil,
        rows: Int = 10,
        columns: Int = 10
    ) -> (engine: GameEngine, store: ScoreStoreMock)
    {
        let store = ScoreStoreMock(storedBest: storedBest)
        let engine = GameEngine(rows: rows, columns: columns, scoreStore: store, rng: seed.map { SeededGenerator(seed: $0) })
        if let colors
        {
            engine.load(colors: colors)
        }
        engine.startGame()
        return (engine, store)
    }

    private func filledBoard(_ color: Int, rows: Int = 10, columns: Int = 10) -> [[Int]]
    {
        Array(repeating: Array(repeating: color, count: columns), count: rows)
    }

    /// Feld ohne mögliche Züge: Farbindex = (Reihe + Spalte) % 5.
    private func diagonalBoard() -> [[Int]]
    {
        (0..<rowCount).map { row in
            (0..<columnCount).map { column in (row + column) % 5 }
        }
    }

    // MARK: - Punkte

    func test_points_forGroupSizes_matchesFormula5n2()
    {
        XCTAssertEqual(GameEngine.points(forGroupSize: 2), 20)
        XCTAssertEqual(GameEngine.points(forGroupSize: 3), 45)
        XCTAssertEqual(GameEngine.points(forGroupSize: 5), 125)
        XCTAssertEqual(GameEngine.points(forGroupSize: 10), 500)
    }

    // MARK: - Bonus

    func test_stageBonus_forRemaining0_returns2000()
    {
        XCTAssertEqual(GameEngine.stageBonus(forRemaining: 0), 2000)
    }

    func test_stageBonus_forRemaining7_returns1020()
    {
        XCTAssertEqual(GameEngine.stageBonus(forRemaining: 7), 1020)
    }

    func test_stageBonus_forRemaining10_returns0()
    {
        XCTAssertEqual(GameEngine.stageBonus(forRemaining: 10), 0)
    }

    func test_stageBonus_forRemaining11_returns0()
    {
        XCTAssertEqual(GameEngine.stageBonus(forRemaining: 11), 0)
    }

    // MARK: - Auswahl

    func test_tap_onLoneTile_returnsRejected()
    {
        var colors = filledBoard(4)
        colors[0][0] = 0
        let (engine, _) = makeEngine(colors: colors)

        XCTAssertEqual(engine.tap(atRow: 0, column: 0), .rejected)
    }

    func test_tap_onDiagonalPair_returnsRejected()
    {
        var colors = filledBoard(4)
        colors[0][0] = 0
        colors[1][1] = 0
        let (engine, _) = makeEngine(colors: colors)

        XCTAssertEqual(engine.tap(atRow: 0, column: 0), .rejected)
    }

    func test_tap_onGroup_selectsAllConnectedTiles()
    {
        var colors = filledBoard(4)
        colors[0][0] = 0
        colors[0][1] = 0
        colors[1][0] = 0
        colors[1][1] = 1
        let (engine, _) = makeEngine(colors: colors)

        XCTAssertEqual(engine.tap(atRow: 0, column: 0), .selected(groupSize: 3))
        XCTAssertEqual(engine.selectedTileIDs.count, 3)
    }

    func test_tap_onSecondTileOfSelectedGroup_popsGroup()
    {
        var colors = filledBoard(4)
        colors[0][0] = 0
        colors[0][1] = 0
        colors[1][0] = 0
        let (engine, _) = makeEngine(colors: colors)

        XCTAssertEqual(engine.tap(atRow: 0, column: 0), .selected(groupSize: 3))
        XCTAssertEqual(engine.tap(atRow: 0, column: 1), .popped(groupSize: 3, points: 45))
        XCTAssertEqual(engine.score, 45)
        XCTAssertTrue(engine.selectedTileIDs.isEmpty)
    }

    // MARK: - Schwerkraft und Spalten

    func test_pop_removesGroup_appliesGravity()
    {
        var colors = filledBoard(4)
        // Oben fünf Farbe-1-Steine, darunter die platzende Farbe-0-Gruppe.
        for row in 0..<5
        {
            colors[row][0] = 1
        }
        for row in 5..<rowCount
        {
            colors[row][0] = 0
        }
        let (engine, _) = makeEngine(colors: colors)

        XCTAssertEqual(engine.tap(atRow: 7, column: 0), .selected(groupSize: 5))
        XCTAssertEqual(engine.tap(atRow: 7, column: 0), .popped(groupSize: 5, points: 125))

        XCTAssertEqual(engine.tiles.count, 95)
        XCTAssertEqual(engine.score, 125)
        // Die fünf Farbe-1-Steine über der Gruppe rutschen auf Reihe 5–9.
        XCTAssertEqual(engine.tile(atRow: 5, column: 0)?.colorIndex, 1)
        XCTAssertEqual(engine.tile(atRow: 9, column: 0)?.colorIndex, 1)
        XCTAssertNil(engine.tile(atRow: 0, column: 0))
        XCTAssertNil(engine.tile(atRow: 4, column: 0))
        // Nachbarspalte bleibt unverändert.
        XCTAssertEqual(engine.tile(atRow: 0, column: 1)?.colorIndex, 4)
    }

    func test_pop_ofEmptyColumn_shiftsColumnsToLeft()
    {
        var colors = filledBoard(4)
        // Spalte 0 komplett in Farbe 3, rechts davon ein einzelner Stein in Spalte 3.
        for row in 0..<rowCount
        {
            colors[row][0] = 3
        }
        colors[9][3] = 2
        let (engine, _) = makeEngine(colors: colors)

        XCTAssertEqual(engine.tap(atRow: 5, column: 0), .selected(groupSize: 10))
        XCTAssertEqual(engine.tap(atRow: 5, column: 0), .popped(groupSize: 10, points: 500))

        XCTAssertEqual(engine.tiles.count, 90)
        // Spalte 0 ist leer → alte Spalte 1 wird Spalte 0, alte Spalte 3 wird Spalte 2.
        XCTAssertEqual(engine.tile(atRow: 9, column: 0)?.colorIndex, 4)
        XCTAssertEqual(engine.tile(atRow: 9, column: 1)?.colorIndex, 4)
        XCTAssertEqual(engine.tile(atRow: 9, column: 2)?.colorIndex, 2)
        XCTAssertEqual(engine.tile(atRow: 9, column: 3)?.colorIndex, 4)
    }

    // MARK: - Stage-Ende

    func test_evaluateStageEnd_whenNoMovesEndsStage_andShowsSummary()
    {
        let (engine, _) = makeEngine(colors: diagonalBoard())

        XCTAssertFalse(engine.hasMoves())
        XCTAssertTrue(engine.evaluateStageEnd())

        guard case .stageFinished(let summary) = engine.phase else
        {
            return XCTFail("Phase sollte stageFinished sein")
        }
        XCTAssertEqual(summary.remaining, rowCount * columnCount)
        XCTAssertEqual(summary.bonus, 0)
        XCTAssertEqual(summary.totalScore, 0)
        XCTAssertFalse(summary.isNewRecord)
    }

    func test_evaluateStageEnd_afterLastPossiblePop_savesNewRecord()
    {
        // Diagonalmuster ohne Züge, plus ein dreisteiniger Austausch oben links.
        // Nach dem Platzen rutschen die Spalten so, dass weiterhin kein Zug bleibt.
        var colors = diagonalBoard()
        colors[0][0] = 4
        colors[0][1] = 4
        colors[1][1] = 4
        let (engine, store) = makeEngine(colors: colors)

        XCTAssertEqual(engine.tap(atRow: 0, column: 0), .selected(groupSize: 3))
        XCTAssertEqual(engine.tap(atRow: 0, column: 0), .popped(groupSize: 3, points: 45))
        XCTAssertFalse(engine.hasMoves())

        XCTAssertTrue(engine.evaluateStageEnd())
        XCTAssertEqual(engine.score, 45)

        guard case .stageFinished(let summary) = engine.phase else
        {
            return XCTFail("Phase sollte stageFinished sein")
        }
        XCTAssertEqual(summary.remaining, rowCount * columnCount - 3)
        XCTAssertEqual(summary.totalScore, 45)
        XCTAssertTrue(summary.isNewRecord)
        XCTAssertEqual(store.savedValues, [45])
    }

    func test_tap_onBoardWithoutMoves_returnsRejected()
    {
        let (engine, _) = makeEngine(colors: diagonalBoard())
        XCTAssertFalse(engine.hasMoves())

        XCTAssertEqual(engine.tap(atRow: 0, column: 0), .rejected)
    }

    // MARK: - Rekord

    func test_init_loadsBestFromStore()
    {
        let store = ScoreStoreMock(storedBest: 500)
        let engine = GameEngine(scoreStore: store)
        XCTAssertEqual(engine.bestScore, 500)
    }

    // MARK: - Feldaufbau

    func test_buildStage_withSeededGenerators_alwaysHasMoves()
    {
        for seed in UInt64(0)..<UInt64(25)
        {
            let store = ScoreStoreMock()
            let engine = GameEngine(scoreStore: store, rng: SeededGenerator(seed: seed))
            XCTAssertTrue(engine.hasMoves(), "Seed \(seed) erzeugte ein Feld ohne Züge")
            XCTAssertEqual(engine.tiles.count, engine.rows * engine.columns)
        }
    }

    func test_init_withCustomBoardSize_8x12_builds96Tiles()
    {
        let store = ScoreStoreMock()
        let engine = GameEngine(rows: 12, columns: 8, scoreStore: store, rng: SeededGenerator(seed: 42))

        XCTAssertEqual(engine.rows, 12)
        XCTAssertEqual(engine.columns, 8)
        XCTAssertEqual(engine.tiles.count, 96)
        XCTAssertNotNil(engine.tile(atRow: 11, column: 7))
        XCTAssertNil(engine.tile(atRow: 11, column: 8))
        XCTAssertNil(engine.tile(atRow: 12, column: 7))
    }

    func test_gravity_andCollapse_workOn8x12Board()
    {
        var colors = filledBoard(4, rows: 12, columns: 8)
        // Untere Hälfte von Spalte 0 in Farbe 0 – Plattzen lässt alles oben fallen.
        for row in 6..<12
        {
            colors[row][0] = 0
        }
        colors[0][0] = 1
        let (engine, _) = makeEngine(colors: colors, rows: 12, columns: 8)

        XCTAssertEqual(engine.tap(atRow: 8, column: 0), .selected(groupSize: 6))
        XCTAssertEqual(engine.tap(atRow: 8, column: 0), .popped(groupSize: 6, points: 180))

        // Die sechs Steine über der Gruppe (Reihe 0–5) rutschen auf Reihe 6–11.
        XCTAssertEqual(engine.tile(atRow: 6, column: 0)?.colorIndex, 1)
        XCTAssertEqual(engine.tile(atRow: 11, column: 0)?.colorIndex, 4)
        XCTAssertNil(engine.tile(atRow: 0, column: 0))
        XCTAssertEqual(engine.score, 180)
    }

    // MARK: - Neustart und Stages

    func test_restart_resetsScoreAndStage_andBuildsFullBoard()
    {
        let (engine, _) = makeEngine(colors: diagonalBoard())
        engine.restart()

        XCTAssertEqual(engine.score, 0)
        XCTAssertEqual(engine.stage, 1)
        XCTAssertEqual(engine.tiles.count, rowCount * columnCount)
        XCTAssertEqual(engine.phase, .playing)
    }

    func test_startNextStage_incrementsStage_andRefillsBoard()
    {
        let (engine, _) = makeEngine(colors: diagonalBoard())
        engine.evaluateStageEnd()
        engine.startNextStage()

        XCTAssertEqual(engine.stage, 2)
        XCTAssertEqual(engine.tiles.count, rowCount * columnCount)
        XCTAssertEqual(engine.phase, .playing)
    }

    // MARK: - Ungültige Eingaben

    func test_tap_whileNotPlaying_returnsNil()
    {
        let store = ScoreStoreMock()
        let engine = GameEngine(scoreStore: store)
        XCTAssertNil(engine.tap(atRow: 0, column: 0))
    }

    // MARK: - Gruppen-Hilfe

    func test_firstGroupTile_returnsTileFromARealGroup()
    {
        var colors = filledBoard(4)
        colors[0][0] = 0
        colors[0][1] = 0
        let (engine, _) = makeEngine(colors: colors)

        guard let tile = engine.firstGroupTile() else
        {
            return XCTFail("Es sollte einen Gruppenstein geben")
        }
        XCTAssertEqual(engine.tap(atRow: tile.row, column: tile.column), .selected(groupSize: 2))
    }

    func test_firstGroupTile_onBoardWithoutMoves_returnsNil()
    {
        let (engine, _) = makeEngine(colors: diagonalBoard())
        XCTAssertNil(engine.firstGroupTile())
    }
}

