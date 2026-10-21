// DiscView.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

/// One disc. Yellow carries an inner ring so the two colors differ by shape as well as hue.
struct DiscView: View {
    let player: Player
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(player.color)
            .overlay {
                if player == .yellow {
                    Circle()
                        .strokeBorder(.black.opacity(0.3), lineWidth: max(1, size * 0.08))
                        .padding(size * 0.2)
                }
            }
            .frame(width: size, height: size)
    }
}
