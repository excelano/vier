// Player.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

enum Player: String, Codable, Sendable {
    case red
    case yellow

    var opponent: Player {
        self == .red ? .yellow : .red
    }
}
