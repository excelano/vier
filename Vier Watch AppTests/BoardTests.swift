// BoardTests.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Testing
@testable import Vier_Watch_App

extension Board {
    /// Builds a board from a picture drawn top row first: `R` red, `Y` yellow, `.` empty.
    init(_ picture: String) {
        self.init()
        let rows = picture.split(separator: "\n").map(Array.init)
        precondition(rows.count == Board.rows && rows.allSatisfy { $0.count == Board.columns })
        for (row, line) in rows.reversed().enumerated() {
            for (column, mark) in line.enumerated() {
                let player: Player? = switch mark {
                case "R": .red
                case "Y": .yellow
                default: nil
                }
                if let player {
                    precondition(drop(player, in: column) == Position(column: column, row: row), "floating disc")
                }
            }
        }
    }
}

func cells(_ pairs: (Int, Int)...) -> Set<Position> {
    Set(pairs.map { Position(column: $0.0, row: $0.1) })
}

struct BoardTests {
    @Test func discLandsInLowestEmptyRow() {
        var board = Board()
        #expect(board.drop(.red, in: 3) == Position(column: 3, row: 0))
        #expect(board.drop(.yellow, in: 3) == Position(column: 3, row: 1))
        #expect(board.drop(.red, in: 0) == Position(column: 0, row: 0))
        #expect(board[3, 1] == .yellow)
        #expect(board.emptyCount(in: 3) == 4)
    }

    @Test func fullColumnRejectsDrop() {
        var board = Board()
        for turn in 0..<Board.rows {
            board.drop(turn.isMultiple(of: 2) ? .red : .yellow, in: 6)
        }
        let before = board
        #expect(!board.canDrop(in: 6))
        #expect(board.drop(.red, in: 6) == nil)
        #expect(board == before)
        #expect(board.legalMoves == [0, 1, 2, 3, 4, 5])
    }

    @Test func outOfRangeColumnRejectsDrop() {
        var board = Board()
        #expect(board.drop(.red, in: -1) == nil)
        #expect(board.drop(.red, in: 7) == nil)
        #expect(board.isEmpty)
    }

    @Test func emptyBoardHasNoOutcome() {
        #expect(Board().outcome == nil)
        #expect(Board.lines.count == 69)
    }

    @Test func horizontalWinAtLeftEdge() throws {
        let board = Board("""
            .......
            .......
            .......
            .......
            YYY....
            RRRR...
            """)
        let win = try #require(board.winner)
        #expect(win.player == .red)
        #expect(Set(win.cells) == cells((0, 0), (1, 0), (2, 0), (3, 0)))
    }

    @Test func horizontalWinAtRightEdgeOfTopRow() throws {
        let board = Board("""
            ...YYYY
            ...RRRY
            ...YYYR
            ...RRRY
            ...YYYR
            ..RRRYR
            """)
        let win = try #require(board.winner)
        #expect(win.player == .yellow)
        #expect(Set(win.cells) == cells((3, 5), (4, 5), (5, 5), (6, 5)))
    }

    @Test func verticalWinAtRightEdge() throws {
        let board = Board("""
            ......Y
            ......Y
            ....R.Y
            ....RRY
            ....YRR
            ....RYR
            """)
        let win = try #require(board.winner)
        #expect(win.player == .yellow)
        #expect(Set(win.cells) == cells((6, 2), (6, 3), (6, 4), (6, 5)))
    }

    @Test func risingDiagonalWinFromCorner() throws {
        let board = Board("""
            .......
            .......
            ...R...
            ..RY...
            .RYY...
            RYYR...
            """)
        let win = try #require(board.winner)
        #expect(win.player == .red)
        #expect(Set(win.cells) == cells((0, 0), (1, 1), (2, 2), (3, 3)))
    }

    @Test func fallingDiagonalWinToCorner() throws {
        let board = Board("""
            ...Y...
            ...RY..
            ...RRY.
            ...YRRY
            ...RYYY
            ...YRRY
            """)
        let win = try #require(board.winner)
        #expect(win.player == .yellow)
        #expect(Set(win.cells) == cells((3, 5), (4, 4), (5, 3), (6, 2)))
    }

    @Test func lastDiscCompletesTheWinningFour() throws {
        var board = Board("""
            .......
            .......
            .......
            .......
            .......
            .RRR...
            """)
        #expect(board.winner == nil)
        #expect(!board.completesFour(at: Position(column: 3, row: 0)))
        let landed = board.drop(.red, in: 4)
        let position = try #require(landed)
        #expect(board.completesFour(at: position))
        let win = try #require(board.winner)
        #expect(Set(win.cells) == cells((1, 0), (2, 0), (3, 0), (4, 0)))
    }

    @Test func threeInARowIsNotAWin() {
        let board = Board("""
            .......
            .......
            .......
            R......
            R......
            RYY.Y..
            """)
        #expect(board.winner == nil)
        #expect(board.outcome == nil)
    }

    @Test func fullBoardWithoutWinnerIsDraw() {
        let board = Board("""
            YYRRYYR
            RRYYRRY
            YYRRYYR
            RRYYRRY
            YYRRYYR
            RRYYRRY
            """)
        #expect(board.isFull)
        #expect(board.winner == nil)
        #expect(board.outcome == .draw)
    }
}
