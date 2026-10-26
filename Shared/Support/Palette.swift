// Palette.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

extension Color {
    static let discRed = Color(red: 0xE6 / 255, green: 0x39 / 255, blue: 0x46 / 255)
    static let discYellow = Color(red: 0xFF / 255, green: 0xC9 / 255, blue: 0x3C / 255)
    static let boardBlue = Color(red: 0x1D / 255, green: 0x35 / 255, blue: 0x57 / 255)
}

extension Player {
    var color: Color {
        self == .red ? .discRed : .discYellow
    }
}
