// GameView.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

struct GameView: View {
    @Environment(GameViewModel.self) private var game
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.difficulty) private var difficulty: Difficulty = .easy
    @State private var crown = 3.0
    @State private var isShowingResult = false
    @FocusState private var isCrownFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            BoardView(board: game.board,
                      hover: game.hover,
                      lastDrop: game.lastDrop,
                      winningCells: game.winningCells,
                      onSelectColumn: game.select,
                      onSwipeDown: game.dropInSelectedColumn,
                      onPlayColumn: game.play(column:))
            if isShowingResult, let title = game.resultTitle {
                ResultPanel(title: title, onPlayAgain: playAgain, onHome: { dismiss() })
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .focusable()
        .focused($isCrownFocused)
        .focusEffectDisabled()
        .digitalCrownRotation($crown, from: 0, through: Double(Board.columns - 1), by: 1,
                              sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crown) {
            game.select(Int(crown.clamped(to: 0...Double(Board.columns - 1)).rounded()))
        }
        .onChange(of: game.selectedColumn, initial: true) {
            crown = Double(game.selectedColumn)
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: game.lastDrop) {
            if let move = game.lastMoveDescription {
                AccessibilityNotification.Announcement(move).post()
            }
        }
        .task(id: game.phase) {
            isShowingResult = false
            guard let title = game.resultTitle else { return }
            try? await Task.sleep(for: .seconds(1))
            withAnimation { isShowingResult = true }
            AccessibilityNotification.Announcement(title).post()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                TurnIndicator(phase: game.phase, turn: game.turn)
            }
        }
        .background(.black)
        .onAppear {
            isCrownFocused = true
            game.resume()
        }
    }

    private func playAgain() {
        game.newGame(mode: game.mode, difficulty: difficulty)
    }
}

private struct TurnIndicator: View {
    let phase: GameViewModel.Phase
    let turn: Player

    var body: some View {
        switch phase {
        case .computerThinking:
            Text("…").font(.footnote.bold())
                .accessibilityLabel("Watch is thinking")
        case .finished:
            EmptyView()
        default:
            Circle().fill(turn.color).frame(width: 10, height: 10)
                .accessibilityLabel(turn == .red ? "Red to move" : "Yellow to move")
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
