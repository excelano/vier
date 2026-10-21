// AIEngine.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

/// The computer opponent: negamax with alpha-beta pruning over `Board`.
enum AIEngine {
    /// Center first, then outward, so the strongest moves are searched first and prune the rest.
    static let searchOrder = [3, 2, 4, 1, 5, 0, 6]

    private static let winScore = 1000

    static func bestMove(on board: Board, for player: Player, difficulty: Difficulty) -> Int {
        var generator = SystemRandomNumberGenerator()
        return bestMove(on: board, for: player, difficulty: difficulty, using: &generator)
    }

    static func bestMove(on board: Board, for player: Player, difficulty: Difficulty,
                         using generator: inout some RandomNumberGenerator) -> Int {
        let moves = searchOrder.filter(board.canDrop)
        precondition(!moves.isEmpty, "no legal move on a full board")

        if let win = immediateWin(on: board, for: player) {
            return win
        }
        if difficulty.blocksImmediateWins, let block = immediateWin(on: board, for: player.opponent) {
            return block
        }
        if Double.random(in: 0..<1, using: &generator) < difficulty.randomMoveChance {
            return moves.randomElement(using: &generator)!
        }

        var search = board
        var bestColumn = moves[0]
        var alpha = -Int.max
        for column in moves {
            let score = score(of: column, on: &search, for: player, depth: difficulty.searchDepth, ply: 0,
                              alpha: -Int.max, beta: -alpha)
            if score > alpha {
                alpha = score
                bestColumn = column
            }
        }
        return bestColumn
    }

    private static func immediateWin(on board: Board, for player: Player) -> Int? {
        var search = board
        return searchOrder.first { column in
            guard let position = search.drop(player, in: column) else { return false }
            defer { search.remove(at: position) }
            return search.completesFour(at: position)
        }
    }

    /// The negamax value, for `player`, of dropping in `column`. Leaves `board` as it found it.
    private static func score(of column: Int, on board: inout Board, for player: Player, depth: Int, ply: Int,
                              alpha: Int, beta: Int) -> Int {
        let position = board.drop(player, in: column)!
        defer { board.remove(at: position) }
        if board.completesFour(at: position) {
            return winScore - (ply + 1)
        }
        return -negamax(&board, for: player.opponent, depth: depth - 1, ply: ply + 1, alpha: -beta, beta: -alpha)
    }

    private static func negamax(_ board: inout Board, for player: Player, depth: Int, ply: Int,
                                alpha: Int, beta: Int) -> Int {
        if board.isFull {
            return 0
        }
        if depth == 0 {
            return evaluate(board, for: player)
        }
        var alpha = alpha
        var best = -Int.max
        for column in searchOrder where board.canDrop(in: column) {
            let score = score(of: column, on: &board, for: player, depth: depth, ply: ply, alpha: alpha, beta: beta)
            best = max(best, score)
            alpha = max(alpha, score)
            if alpha >= beta {
                break
            }
        }
        return best
    }

    /// Scores a position with no winner yet, from `player`'s side.
    private static func evaluate(_ board: Board, for player: Player) -> Int {
        var score = 0
        for row in 0..<Board.rows where board[3, row] == player {
            score += 3
        }
        for line in Board.lines {
            var own = 0
            var opponent = 0
            for position in line {
                switch board[position] {
                case player: own += 1
                case nil: break
                default: opponent += 1
                }
            }
            switch (own, opponent) {
            case (3, 0): score += 5
            case (2, 0): score += 2
            case (0, 3): score -= 4
            default: break
            }
        }
        return score
    }
}
