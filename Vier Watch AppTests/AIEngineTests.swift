// AIEngineTests.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Testing
@testable import Vier_Watch_App

/// SplitMix64, so the randomized difficulty is repeatable under test.
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

func move(on board: Board, for player: Player, difficulty: Difficulty, seed: UInt64 = 1) -> Int {
    var generator = SeededGenerator(state: seed)
    return AIEngine.bestMove(on: board, for: player, difficulty: difficulty, using: &generator)
}

@Suite(.serialized)
struct AIEngineTests {
    static let winning: [(name: String, board: Board, player: Player, columns: Set<Int>)] = [
        ("horizontal", Board("""
            .......
            .......
            .......
            .......
            ..RR...
            .YYY.R.
            """), .yellow, [0, 4]),
        ("vertical", Board("""
            .......
            .......
            .......
            R......
            R...Y..
            R..YY..
            """), .red, [0]),
        ("diagonal", Board("""
            .......
            .......
            .......
            ..YR...
            .YRY...
            YRYR...
            """), .yellow, [3]),
    ]

    static let blocking: [(name: String, board: Board, columns: Set<Int>)] = [
        ("horizontal", Board("""
            .......
            .......
            .......
            .......
            ...Y...
            YRRR.Y.
            """), [4]),
        ("vertical", Board("""
            .......
            .......
            .......
            ..R....
            ..R.Y..
            ..R.YY.
            """), [2]),
        ("diagonal", Board("""
            .......
            .......
            .......
            ..RY...
            .RYR...
            RYRY...
            """), [3]),
    ]

    @Test(arguments: Difficulty.allCases)
    func takesImmediateWin(difficulty: Difficulty) {
        for (name, board, player, columns) in Self.winning {
            for seed in UInt64(0)..<40 {
                let column = move(on: board, for: player, difficulty: difficulty, seed: seed)
                #expect(columns.contains(column), "\(name) win missed with seed \(seed)")
            }
        }
    }

    @Test(arguments: [Difficulty.medium, .hard])
    func blocksImmediateWin(difficulty: Difficulty) {
        for (name, board, columns) in Self.blocking {
            #expect(columns.contains(move(on: board, for: .yellow, difficulty: difficulty)), "\(name) block missed")
        }
    }

    @Test func prefersOwnWinOverBlock() {
        let board = Board("""
            .......
            .......
            .......
            ......Y
            ......Y
            .RRR..Y
            """)
        for difficulty in Difficulty.allCases {
            #expect(move(on: board, for: .yellow, difficulty: difficulty) == 6)
        }
    }

    @Test func playsTheOnlyOpenColumn() {
        let board = Board("""
            RYRY.YR
            RYRY.YR
            YRYRRRY
            YRYRYRY
            RYRYRYR
            RYRYRYR
            """)
        for difficulty in Difficulty.allCases {
            #expect(move(on: board, for: .red, difficulty: difficulty) == 4)
        }
    }

    @Test(arguments: Difficulty.allCases)
    func neverReturnsIllegalColumn(difficulty: Difficulty) {
        var generator = SeededGenerator(state: 7)
        let games = difficulty == .hard ? 3 : 20
        for game in 0..<games {
            var board = Board()
            var player = Player.red
            while board.outcome == nil {
                let column = move(on: board, for: player, difficulty: difficulty, seed: UInt64(game * 100 + board.cells.count(where: { $0 != nil })))
                #expect(board.canDrop(in: column), "illegal column \(column)")
                guard board.canDrop(in: column) else { return }
                let chosen = Bool.random(using: &generator) ? column : board.legalMoves.randomElement(using: &generator)!
                board.drop(player, in: chosen)
                player = player.opponent
            }
        }
    }

    @Test func hardSearchIsFastFromEmptyBoard() {
        let elapsed = ContinuousClock().measure {
            _ = move(on: Board(), for: .red, difficulty: .hard)
        }
        #expect(elapsed < .seconds(1), "took \(elapsed)")
    }

    @Test func hardSearchIsFastFromMidGame() {
        var board = Board()
        for (index, column) in [3, 3, 2, 4, 4, 2, 5, 1, 1, 5].enumerated() {
            board.drop(index.isMultiple(of: 2) ? .red : .yellow, in: column)
        }
        #expect(board.outcome == nil)
        let elapsed = ContinuousClock().measure {
            _ = move(on: board, for: .red, difficulty: .hard)
        }
        #expect(elapsed < .seconds(1), "took \(elapsed)")
    }
}
