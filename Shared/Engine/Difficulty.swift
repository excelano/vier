// Difficulty.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

enum Difficulty: String, CaseIterable, Codable, CodingKeyRepresentable, Identifiable, Sendable {
    case easy
    case medium
    case hard

    var id: Self { self }

    var title: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }

    var searchDepth: Int {
        switch self {
        case .easy: 1
        case .medium: 2
        case .hard: 4
        }
    }

    /// How often the engine plays a random legal move instead of searching.
    var randomMoveChance: Double {
        switch self {
        case .easy: 0.65
        case .medium: 0.5
        case .hard: 0
        }
    }

    /// Whether the engine always blocks an opponent's immediate win before searching.
    var blocksImmediateWins: Bool {
        self != .easy
    }
}
