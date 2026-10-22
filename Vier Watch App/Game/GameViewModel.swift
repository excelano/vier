// GameViewModel.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Observation

enum StorageKey {
    static let difficulty = "difficulty"
    static let savedGame = "savedGame"
    static let nextStarter = "nextStarter"
    static let mode = "mode"
}

@Observable @MainActor
final class GameViewModel {
    enum Mode: String, CaseIterable, Codable, Identifiable {
        case versusWatch
        case hotSeat

        var id: Self { self }

        var title: String {
            switch self {
            case .versusWatch: "Against the watch"
            case .hotSeat: "Two players"
            }
        }
    }

    enum Phase: Equatable {
        case playerTurn
        case animatingDrop
        case computerThinking
        case finished(Outcome)
    }

    static let dropDuration: Duration = .milliseconds(300)
    static let thinkingDelay: Duration = .milliseconds(400)
    static let hoverDuration: Duration = .milliseconds(250)

    private(set) var board = Board()
    private(set) var turn: Player = .red
    private(set) var phase: Phase = .playerTurn
    private(set) var mode: Mode = .versusWatch
    private(set) var difficulty: Difficulty = .easy
    private(set) var starter: Player = .red
    private(set) var lastDrop: Position?
    private(set) var selectedColumn = 3
    private var computerColumn: Int?
    private var turnTask: Task<Void, Never>?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restore()
    }

    var hasGameInProgress: Bool {
        !board.isEmpty && board.outcome == nil
    }

    /// The disc hovering over the selector row, if one should show.
    var hover: (player: Player, column: Int)? {
        switch phase {
        case .playerTurn: (turn, selectedColumn)
        case .computerThinking: computerColumn.map { (.yellow, $0) }
        default: nil
        }
    }

    var winningCells: Set<Position> {
        if case .finished(.win(let win)) = phase { Set(win.cells) } else { [] }
    }

    var resultTitle: String? {
        guard case .finished(let outcome) = phase else { return nil }
        guard case .win(let win) = outcome else { return "Draw" }
        return switch (mode, win.player) {
        case (.versusWatch, .red): "You win!"
        case (.versusWatch, .yellow): "Watch wins"
        case (.hotSeat, .red): "Red wins!"
        case (.hotSeat, .yellow): "Yellow wins!"
        }
    }

    /// The last move, as VoiceOver reads it: "Watch played column 3. Column 3 has 4 empty."
    var lastMoveDescription: String? {
        guard let lastDrop, let player = board[lastDrop] else { return nil }
        let name = switch (mode, player) {
        case (.versusWatch, .red): "You"
        case (.versusWatch, .yellow): "Watch"
        case (.hotSeat, .red): "Red"
        case (.hotSeat, .yellow): "Yellow"
        }
        let column = lastDrop.column + 1
        return "\(name) played column \(column). Column \(column) has \(board.emptyCount(in: lastDrop.column)) empty."
    }

    /// Starts a game. Against the watch, who moves first alternates from game to game,
    /// starting with the player on a fresh install.
    func newGame(mode: Mode, difficulty: Difficulty) {
        turnTask?.cancel()
        self.mode = mode
        self.difficulty = difficulty
        if mode == .versusWatch {
            starter = defaults.string(forKey: StorageKey.nextStarter).flatMap(Player.init) ?? .red
            defaults.set(starter.opponent.rawValue, forKey: StorageKey.nextStarter)
        } else {
            starter = .red
        }
        board = Board()
        turn = starter
        lastDrop = nil
        selectedColumn = 3
        beginTurn()
    }

    /// Discards the game in progress, so the next Play starts a new one.
    func abandonGame() {
        turnTask?.cancel()
        board = Board()
        lastDrop = nil
        phase = .playerTurn
        save()
    }

    /// Picks up a restored game whose next move is the watch's.
    func resume() {
        if phase == .computerThinking && turnTask == nil {
            playComputerTurn()
        }
    }

    /// Moves the selector toward `column`, skipping full columns where it can.
    func select(_ column: Int) {
        guard phase == .playerTurn, column != selectedColumn else { return }
        let step = column > selectedColumn ? 1 : -1
        selectedColumn = openColumn(from: column, step: step) ?? openColumn(from: column, step: -step) ?? column
    }

    func dropInSelectedColumn() {
        play(column: selectedColumn)
    }

    /// Drops the current player's disc in `column`, or plays a failure haptic when it is full.
    func play(column: Int) {
        guard phase == .playerTurn else { return }
        guard board.canDrop(in: column) else {
            Haptics.play(.failure)
            return
        }
        selectedColumn = column
        drop(in: column)
    }

    /// Saves the game in progress, or clears the saved game when there is none.
    func save() {
        guard hasGameInProgress else {
            defaults.removeObject(forKey: StorageKey.savedGame)
            return
        }
        let toMove = phase == .animatingDrop ? turn.opponent : turn
        let saved = SavedGame(board: board, turn: toMove, starter: starter, difficulty: difficulty, mode: mode)
        defaults.set(try? JSONEncoder().encode(saved), forKey: StorageKey.savedGame)
    }

    #if DEBUG
    /// Sets up a position against the watch for screenshots: `columns` played alternately, red first.
    func loadDemo(columns: [Int]) {
        turnTask?.cancel()
        turnTask = nil
        mode = .versusWatch
        board = Board()
        turn = .red
        for column in columns {
            board.drop(turn, in: column)
            turn = turn.opponent
        }
        if let outcome = board.outcome {
            phase = .finished(outcome)
        } else {
            phase = isHuman(turn) ? .playerTurn : .computerThinking
        }
    }
    #endif

    private func restore() {
        guard let data = defaults.data(forKey: StorageKey.savedGame),
              let saved = try? JSONDecoder().decode(SavedGame.self, from: data),
              saved.board.outcome == nil
        else { return }
        board = saved.board
        turn = saved.turn
        starter = saved.starter
        difficulty = saved.difficulty
        mode = saved.mode
        selectedColumn = openColumn(from: 3, step: 1) ?? openColumn(from: 3, step: -1) ?? 3
        phase = isHuman(turn) ? .playerTurn : .computerThinking
    }

    private func drop(in column: Int) {
        guard let position = board.drop(turn, in: column) else { return }
        lastDrop = position
        phase = .animatingDrop
        Haptics.play(isHuman(turn) ? .click : .directionDown)
        turnTask = Task {
            try? await Task.sleep(for: Self.dropDuration)
            guard !Task.isCancelled else { return }
            finishDrop()
        }
    }

    private func finishDrop() {
        if let outcome = board.outcome {
            finish(with: outcome)
            return
        }
        turn = turn.opponent
        beginTurn()
        save()
    }

    private func finish(with outcome: Outcome) {
        phase = .finished(outcome)
        switch outcome {
        case .win(let win) where isHuman(win.player): Haptics.play(.success)
        case .win: Haptics.play(.retry)
        case .draw: Haptics.play(.notification)
        }
        save()
    }

    private func beginTurn() {
        selectedColumn = openColumn(from: selectedColumn, step: 1) ?? openColumn(from: selectedColumn, step: -1) ?? selectedColumn
        if isHuman(turn) {
            phase = .playerTurn
        } else {
            playComputerTurn()
        }
    }

    /// Searches off the main actor, waits out a short pause, then slides the yellow disc to its column.
    private func playComputerTurn() {
        phase = .computerThinking
        computerColumn = selectedColumn
        let board = board
        let player = turn
        let difficulty = difficulty
        turnTask = Task {
            let search = Task.detached(priority: .userInitiated) {
                AIEngine.bestMove(on: board, for: player, difficulty: difficulty)
            }
            try? await Task.sleep(for: Self.thinkingDelay)
            let column = await search.value
            guard !Task.isCancelled else { return }
            computerColumn = column
            try? await Task.sleep(for: Self.hoverDuration)
            guard !Task.isCancelled else { return }
            computerColumn = nil
            drop(in: column)
        }
    }

    private func isHuman(_ player: Player) -> Bool {
        mode == .hotSeat || player == .red
    }

    private func openColumn(from column: Int, step: Int) -> Int? {
        stride(from: column, to: step > 0 ? Board.columns : -1, by: step).first(where: board.canDrop)
    }
}

private struct SavedGame: Codable {
    let board: Board
    let turn: Player
    let starter: Player
    let difficulty: Difficulty
    let mode: GameViewModel.Mode
}
