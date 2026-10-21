// ResultPanel.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

struct ResultPanel: View {
    let title: String
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                CompactButton(title: "Play again", fill: .discRed, action: onPlayAgain)
                CompactButton(title: "Home", fill: .gray.opacity(0.45), action: onHome)
            }
        }
        .padding(.horizontal, 6)
    }
}

private struct CompactButton: View {
    let title: String
    let fill: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(fill, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
