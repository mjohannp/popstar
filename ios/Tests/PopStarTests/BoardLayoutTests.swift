import XCTest
@testable import PopStar

/// Skalierungs-Verhalten des Layouts für verschiedene Feldgrößen.
final class BoardLayoutTests: XCTestCase
{
    func test_layout_for10x10_inSquareSpace_fitsBothDimensions()
    {
        let layout = BoardLayout(availableWidth: 400, availableHeight: 400, rows: 10, columns: 10)

        XCTAssertLessThanOrEqual(layout.boardWidth, 400)
        XCTAssertLessThanOrEqual(layout.boardHeight, 400)
        XCTAssertEqual(layout.boardWidth, layout.boardHeight, accuracy: 1)
        XCTAssertGreaterThan(layout.tileSize, 30)
    }

    func test_layout_for8x12Portrait_fitsIntoAvailableSpace()
    {
        let layout = BoardLayout(availableWidth: 390, availableHeight: 700, rows: 12, columns: 8)

        XCTAssertLessThanOrEqual(layout.boardWidth, 390)
        XCTAssertLessThanOrEqual(layout.boardHeight, 700)
        // Die Breite begrenzt: 8 Spalten dürfen nicht in mehr Platz gequetscht
        // werden, und die Höhe darf nicht verzerren.
        XCTAssertGreaterThan(layout.tileSize, 36)
        XCTAssertLessThanOrEqual(layout.tileSize, 48)
    }

    func test_layout_for12x8Landscape_fitsIntoAvailableSpace()
    {
        let layout = BoardLayout(availableWidth: 390, availableHeight: 500, rows: 8, columns: 12)

        XCTAssertLessThanOrEqual(layout.boardWidth, 390)
        XCTAssertLessThanOrEqual(layout.boardHeight, 500)
        XCTAssertGreaterThan(layout.tileSize, 25)
    }

    func test_layout_narrowSpace_scalesDownInsteadOfOverflowing()
    {
        let layout = BoardLayout(availableWidth: 200, availableHeight: 420, rows: 12, columns: 8)

        XCTAssertLessThanOrEqual(layout.boardWidth, 200)
        XCTAssertLessThanOrEqual(layout.boardHeight, 420)
        XCTAssertGreaterThan(layout.tileSize, 18)
    }

    func test_layout_forTinySpace_keepsMinimumTileSize()
    {
        let layout = BoardLayout(availableWidth: 60, availableHeight: 60, rows: 12, columns: 8)

        XCTAssertGreaterThanOrEqual(layout.cellSize, 4)
        XCTAssertLessThanOrEqual(layout.boardWidth, 60 + 8)
        XCTAssertLessThanOrEqual(layout.boardHeight, 60 + 8)
    }

    func test_layout_positions_stayInsideBoard()
    {
        let layout = BoardLayout(availableWidth: 390, availableHeight: 700, rows: 12, columns: 8)

        let first = layout.position(of: TileModel(id: 0, colorIndex: 0, row: 0, column: 0))
        let last = layout.position(of: TileModel(id: 1, colorIndex: 0, row: 11, column: 7))

        XCTAssertGreaterThan(first.x, 0)
        XCTAssertGreaterThan(first.y, 0)
        XCTAssertLessThan(last.x, layout.boardWidth)
        XCTAssertLessThan(last.y, layout.boardHeight)
    }

    func test_layout_margins_areSymmetric()
    {
        let layout = BoardLayout(availableWidth: 390, availableHeight: 700, rows: 12, columns: 8)

        let leftMargin = layout.position(of: TileModel(id: 0, colorIndex: 0, row: 0, column: 0)).x - layout.tileSize / 2
        let rightMargin = layout.boardWidth - (layout.position(of: TileModel(id: 0, colorIndex: 0, row: 0, column: 7)).x + layout.tileSize / 2)
        XCTAssertEqual(leftMargin, rightMargin, accuracy: 0.5)
    }
}
