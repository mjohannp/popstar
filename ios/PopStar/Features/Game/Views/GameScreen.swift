import SwiftUI

/// Hauptszene: HUD, Spielfeld, Statuszeile und Overlays.
struct GameScreen: View
{
    /// Feldgröße: 8 Spalten × 12 Reihen – beliebig änderbar.
    @State private var engine = GameEngine(rows: 12, columns: 8)
    @State private var soundPlayer = SoundPlayer()
    @State private var hapticsPlayer = HapticsPlayer()

    @AppStorage("popstar.isSoundOn") private var isSoundOn = true
    @State private var isPopCoolDown = false
    @State private var isRestartDialogShown = false
    @State private var shakingTileID: TileModel.ID?
    /// Dev-Hilfe: Start-Argument `-slowAnims` bremst alle Animationen.
    @State private var isSlowMotion = false

    var body: some View
    {
        ZStack
        {
            AppBackground()
            slowable(gameContent)
            overlay
        }
        .alert("Wirklich neu starten?", isPresented: $isRestartDialogShown)
        {
            Button("Abbrechen", role: .cancel) {}
            Button("Neu starten", role: .destructive) { restart() }
        } message: {
            Text("Der Punktestand geht verloren.")
        }
        .onChange(of: isSoundOn) { _, newValue in soundPlayer.setMuted(!newValue) }
        .onAppear
        {
            soundPlayer.setMuted(!isSoundOn)
            let arguments = ProcessInfo.processInfo.arguments
            isSlowMotion = arguments.contains("-slowAnims")
            // Start-Argumente für UI-Tests, Screenshots und Demo-Aufnahmen.
            if arguments.contains("-skipIntro")
            {
                engine.startGame()
            }
            if arguments.contains("-demoPop")
            {
                engine.startGame()
                runDemoPop()
            }
        }
    }

    // MARK: - Aufbau

    /// Wendet optional eine verlangsamte Animation auf den gesamten Inhalt an
    /// (Start-Argument `-slowAnims`, für Screenshots und Aufnahmen).
    @ViewBuilder
    private func slowable(_ content: some View) -> some View
    {
        if isSlowMotion
        {
            content.transaction { transaction in
                transaction.animation = transaction.animation?.speed(0.15)
            }
        }
        else
        {
            content
        }
    }

    private var gameContent: some View
    {
        GeometryReader { proxy in
            // Für HUD und Leiste bleibt ein fester Streifen übrig; der Rest
            // gehört dem Feld, das sich aus Breite UND Höhe rechnet.
            let boardSpace = CGSize(width: proxy.size.width, height: proxy.size.height - 150)

            VStack(spacing: Design.spacing)
            {
                HudView(stage: engine.stage, score: engine.score, bestScore: max(engine.bestScore, engine.score))
                Spacer(minLength: 0)
                BoardView(engine: engine, availableSize: boardSpace, shakingTileID: shakingTileID, onTap: handleTap)
                Spacer(minLength: 0)
                FooterView(
                    info: footerInfo,
                    isSoundOn: isSoundOn,
                    onToggleSound: { isSoundOn.toggle() },
                    onRestart: { isRestartDialogShown = true }
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .padding(.horizontal, Design.horizontalPadding)
    }

    @ViewBuilder
    private var overlay: some View
    {
        switch engine.phase
        {
        case .intro:
            OverlayView(
                title: "Pop Star",
                message: "Tippe auf zusammenhängende Sterne (2 oder mehr) – tippe ein zweites Mal, um sie platzen zu lassen. Je größer die Gruppe, desto mehr Punkte.",
                rows: [
                    OverlayRow(label: "Formel", value: "5 × Blöcke²"),
                    OverlayRow(label: "Ziel", value: "Möglichst viele Stages"),
                ],
                buttonTitle: "Los geht's"
            )
            {
                withAnimation(.easeInOut(duration: 0.2)) { engine.startGame() }
            }

        case .playing:
            EmptyView()

        case .stageFinished(let summary):
            OverlayView(
                title: "Stage \(summary.stage) geschafft",
                message: summary.bonus > 0
                    ? "Stark! Für die übrigen Blöcke gibt es einen Bonus."
                    : "Kein Bonus – es waren mehr als 10 Blöcke übrig.",
                rows: stageRows(for: summary),
                buttonTitle: "Nächste Stage"
            )
            {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { engine.startNextStage() }
            }
        }
    }

    private func stageRows(for summary: GameEngine.StageSummary) -> [OverlayRow]
    {
        var rows = [
            OverlayRow(label: "Blöcke übrig", value: String(summary.remaining)),
            OverlayRow(label: "Bonus", value: summary.bonus > 0 ? "+\(summary.bonus)" : "–"),
            OverlayRow(label: "Punkte gesamt", value: summary.totalScore.formatted()),
        ]
        if summary.isNewRecord
        {
            rows.append(OverlayRow(label: "Neuer Rekord", value: "★"))
        }
        return rows
    }

    // MARK: - Abgeleiteter Zustand

    private var footerInfo: FooterInfo
    {
        if !engine.selectedTileIDs.isEmpty
        {
            let size = engine.selectedTileIDs.count
            return .selection(groupSize: size, points: GameEngine.points(forGroupSize: size))
        }
        return .remaining(engine.tiles.count)
    }

    // MARK: - Aktionen

    private func handleTap(_ tile: TileModel)
    {
        guard !isPopCoolDown else { return }

        // Der Spielzug muss in einer animierten Transaction laufen, damit
        // Platzen (Transition) und Fallen (Position) animiert werden.
        let outcome = withAnimation(Design.popAnimation)
        {
            engine.tap(atRow: tile.row, column: tile.column)
        }
        guard let outcome else { return }

        switch outcome
        {
        case .selected:
            soundPlayer.play(.select)
            hapticsPlayer.fire(.light)

        case .popped(let groupSize, _):
            soundPlayer.play(.pop(count: groupSize))
            hapticsPlayer.fire(.medium)
            startPopCoolDown()
            scheduleStageEndCheck()

        case .rejected:
            shakeRejected(tile)
        }
    }

    private func startPopCoolDown()
    {
        isPopCoolDown = true
        Task { @MainActor in
            try? await Task.sleep(for: Design.popCoolDown)
            isPopCoolDown = false
        }
    }

    private func scheduleStageEndCheck()
    {
        Task { @MainActor in
            try? await Task.sleep(for: Design.stageEndDelay)
            let didEnd = withAnimation(.easeInOut(duration: 0.25)) { engine.evaluateStageEnd() }
            if didEnd
            {
                soundPlayer.play(.stageCleared)
                hapticsPlayer.fire(.success)
            }
        }
    }

    private func shakeRejected(_ tile: TileModel)
    {
        withAnimation(.easeOut(duration: 0.3)) { shakingTileID = tile.id }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.34))
            shakingTileID = nil
        }
    }

    private func restart()
    {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { engine.restart() }
    }

    /// Spielt einen Beispielzug ab (Start-Argument `-demoPop`), um die
    /// Animationen auf Screenshots und Aufnahmen sichtbar zu machen.
    private func runDemoPop()
    {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            guard let tile = engine.firstGroupTile() else { return }

            handleTap(tile)
            try? await Task.sleep(for: .seconds(0.3))
            handleTap(tile)
        }
    }
}

#Preview
{
    GameScreen()
}
