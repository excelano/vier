// GameViewModelTests.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import Vier_Watch_App

@MainActor
struct GameViewModelTests {
    /// Long enough for a drop animation to finish.
    let settle: Duration = GameViewModel.dropDuration + .milliseconds(150)

    func makeGame(defaults: UserDefaults = UserDefaults(suiteName: UUID().uuidString)!) -> GameViewModel {
        GameViewModel(defaults: defaults)
    }

    @Test func playDropsInColumnAndPassesTurn() async throws {
        let game = makeGame()
        game.newGame(mode: .hotSeat, difficulty: .easy)
        game.play(column: 5)
        #expect(game.board[5, 0] == .red)
        #expect(game.phase == .animatingDrop)
        try await Task.sleep(for: settle)
        #expect(game.phase == .playerTurn)
        #expect(game.turn == .yellow)
    }

    @Test func inputIsIgnoredWhileDiscFalls() {
        let game = makeGame()
        game.newGame(mode: .hotSeat, difficulty: .easy)
        game.play(column: 1)
        game.play(column: 2)
        #expect(game.board[2, 0] == nil)
    }

    @Test func swipeDropsInSelectedColumn() {
        let game = makeGame()
        game.newGame(mode: .hotSeat, difficulty: .easy)
        game.select(1)
        game.dropInSelectedColumn()
        #expect(game.board[1, 0] == .red)
    }

    @Test func selectionSkipsFullColumnsAndFullColumnIsRejected() async throws {
        let game = makeGame()
        game.newGame(mode: .hotSeat, difficulty: .easy)
        for _ in 0..<Board.rows {
            game.play(column: 4)
            try await Task.sleep(for: settle)
        }
        #expect(!game.board.canDrop(in: 4))
        game.play(column: 4)
        #expect(game.phase == .playerTurn)

        game.select(3)
        game.select(4)
        #expect(game.selectedColumn == 5)
        game.select(4)
        #expect(game.selectedColumn == 3)
    }

    @Test func watchRepliesWithYellow() async throws {
        let game = makeGame()
        game.newGame(mode: .versusComputer, difficulty: .medium)
        #expect(game.starter == .red)
        game.play(column: 3)
        try await Task.sleep(for: settle + GameViewModel.thinkingDelay + GameViewModel.hoverDuration + settle)
        #expect(game.board.cells.count(where: { $0 == .yellow }) == 1)
        #expect(game.turn == .red)
        #expect(game.phase == .playerTurn)
    }

    @Test func firstMoveAlternatesAgainstTheWatch() {
        let game = makeGame()
        game.newGame(mode: .versusComputer, difficulty: .easy)
        #expect(game.starter == .red)
        game.newGame(mode: .versusComputer, difficulty: .easy)
        #expect(game.starter == .yellow)
        #expect(game.phase == .computerThinking)
        game.newGame(mode: .versusComputer, difficulty: .easy)
        #expect(game.starter == .red)
    }

    @Test func savedGameRestoresPositionAndTurn() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let game = makeGame(defaults: defaults)
        game.newGame(mode: .hotSeat, difficulty: .hard)
        game.play(column: 2)
        game.save()

        let restored = makeGame(defaults: defaults)
        #expect(restored.board == game.board)
        #expect(restored.turn == .yellow)
        #expect(restored.mode == .hotSeat)
        #expect(restored.difficulty == .hard)
        #expect(restored.phase == .playerTurn)
    }

    @Test func finishedGameIsNotSaved() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let game = makeGame(defaults: defaults)
        game.newGame(mode: .versusComputer, difficulty: .medium)
        game.loadDemo(columns: [0, 6, 0, 6, 0, 6])
        game.play(column: 0)
        try await Task.sleep(for: settle)
        #expect(game.resultTitle == "You win!")
        #expect(defaults.data(forKey: StorageKey.savedGame) == nil)
        #expect(!makeGame(defaults: defaults).hasGameInProgress)
    }
}
