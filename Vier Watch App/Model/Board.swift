// Board.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

struct Position: Hashable, Codable, Sendable {
    let column: Int
    let row: Int
}

struct Win: Hashable, Sendable {
    let player: Player
    let cells: [Position]
}

enum Outcome: Hashable, Sendable {
    case win(Win)
    case draw
}

/// A Connect Four board. Row 0 is the bottom row.
struct Board: Hashable, Codable, Sendable {
    static let columns = 7
    static let rows = 6

    /// Every run of four cells that can win: horizontal, vertical and both diagonals.
    static let lines: [[Position]] = {
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        var lines: [[Position]] = []
        for column in 0..<columns {
            for row in 0..<rows {
                for (dc, dr) in directions {
                    let line = (0..<4).map { Position(column: column + dc * $0, row: row + dr * $0) }
                    if line.allSatisfy(contains) {
                        lines.append(line)
                    }
                }
            }
        }
        return lines
    }()

    /// The lines through each cell, indexed by `index(of:)`.
    private static let linesThroughCell: [[[Position]]] = {
        var table = Array(repeating: [[Position]](), count: columns * rows)
        for line in lines {
            for position in line {
                table[index(of: position)].append(line)
            }
        }
        return table
    }()

    private(set) var cells: [Player?] = Array(repeating: nil, count: columns * rows)

    static func contains(_ position: Position) -> Bool {
        (0..<columns).contains(position.column) && (0..<rows).contains(position.row)
    }

    private static func index(of position: Position) -> Int {
        position.row * columns + position.column
    }

    subscript(position: Position) -> Player? {
        cells[Self.index(of: position)]
    }

    subscript(column: Int, row: Int) -> Player? {
        self[Position(column: column, row: row)]
    }

    func emptyCount(in column: Int) -> Int {
        (0..<Self.rows).count(where: { self[column, $0] == nil })
    }

    func canDrop(in column: Int) -> Bool {
        (0..<Self.columns).contains(column) && self[column, Self.rows - 1] == nil
    }

    var legalMoves: [Int] {
        (0..<Self.columns).filter(canDrop)
    }

    var isFull: Bool {
        !(0..<Self.columns).contains(where: canDrop)
    }

    var isEmpty: Bool {
        cells.allSatisfy { $0 == nil }
    }

    /// Drops a disc into `column` and returns where it landed, or nil when the column is full.
    @discardableResult
    mutating func drop(_ player: Player, in column: Int) -> Position? {
        guard canDrop(in: column),
              let row = (0..<Self.rows).first(where: { self[column, $0] == nil })
        else { return nil }
        let position = Position(column: column, row: row)
        cells[Self.index(of: position)] = player
        return position
    }

    /// Takes back the disc at `position`, which must be the top disc of its column.
    mutating func remove(at position: Position) {
        cells[Self.index(of: position)] = nil
    }

    var winner: Win? {
        Self.lines.lazy.compactMap { win(on: $0) }.first
    }

    /// Whether the disc at `position` is part of four in a row.
    func completesFour(at position: Position) -> Bool {
        guard let player = self[position] else { return false }
        return Self.linesThroughCell[Self.index(of: position)].contains { line in
            line.allSatisfy { self[$0] == player }
        }
    }

    var outcome: Outcome? {
        if let winner {
            .win(winner)
        } else if isFull {
            .draw
        } else {
            nil
        }
    }

    private func win(on line: [Position]) -> Win? {
        guard let player = self[line[0]], line.allSatisfy({ self[$0] == player }) else { return nil }
        return Win(player: player, cells: line)
    }
}
