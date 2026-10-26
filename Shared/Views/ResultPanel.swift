// ResultPanel.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

struct ResultPanel: View {
    #if os(watchOS)
    static let titleFont = Font.headline
    static let spacing: CGFloat = 4
    #else
    static let titleFont = Font.title.bold()
    static let spacing: CGFloat = 16
    #endif

    let title: String
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: Self.spacing) {
            Text(title)
                .font(Self.titleFont)
                .multilineTextAlignment(.center)
            HStack(spacing: Self.spacing * 1.5) {
                CompactButton(title: "Play again", fill: .discRed, action: onPlayAgain)
                CompactButton(title: "Home", fill: .gray.opacity(0.45), action: onHome)
            }
        }
        .padding(.horizontal, Self.spacing * 1.5)
    }
}

private struct CompactButton: View {
    #if os(watchOS)
    static let font = Font.footnote.weight(.semibold)
    static let height: CGFloat = 32
    #else
    static let font = Font.headline
    static let height: CGFloat = 50
    #endif

    let title: String
    let fill: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Self.font)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: Self.height)
                .background(fill, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
