// HomeView.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

struct HomeView: View {
    @Environment(GameViewModel.self) private var game
    @AppStorage(StorageKey.difficulty) private var difficulty: Difficulty = .easy
    @State private var isPlaying = false
    @State private var isHotSeat = false
    @State private var pendingDifficulty: Difficulty?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    title
                    Button("Play", action: play)
                        .buttonStyle(.borderedProminent)
                        .tint(.discRed)
                    if isHotSeat {
                        Text("Two players").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Picker("Difficulty", selection: difficultySelection) {
                            ForEach(Difficulty.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
            }
            .navigationDestination(isPresented: $isPlaying) { GameView() }
            .alert("Start a new game?", isPresented: isConfirmingDifficulty, presenting: pendingDifficulty) { choice in
                Button("New game") {
                    difficulty = choice
                    game.abandonGame()
                }
                Button("Cancel", role: .cancel) {}
            } message: { choice in
                Text("Switching to \(choice.title) ends the game in progress.")
            }
        }
        #if DEBUG
        .onAppear(perform: applyLaunchArguments)
        #endif
    }

    /// Holding the title toggles two-player hot-seat play, a debug mode.
    private var title: some View {
        HStack(spacing: 6) {
            DiscView(player: .red, size: 14)
            Text("Vier").font(.title2.bold())
            DiscView(player: .yellow, size: 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Vier")
        .accessibilityAddTraits(.isHeader)
        .onLongPressGesture(minimumDuration: 2) { isHotSeat.toggle() }
    }

    /// Changing difficulty with a game in progress asks first, because it ends that game.
    private var difficultySelection: Binding<Difficulty> {
        Binding {
            difficulty
        } set: { choice in
            if choice != difficulty && game.hasGameInProgress && game.mode == .versusWatch {
                pendingDifficulty = choice
            } else {
                difficulty = choice
            }
        }
    }

    private var isConfirmingDifficulty: Binding<Bool> {
        Binding {
            pendingDifficulty != nil
        } set: { isPresented in
            if !isPresented { pendingDifficulty = nil }
        }
    }

    private func play() {
        let mode: GameViewModel.Mode = isHotSeat ? .hotSeat : .versusWatch
        if !game.hasGameInProgress || game.mode != mode {
            game.newGame(mode: mode, difficulty: difficulty)
        }
        isPlaying = true
    }

    #if DEBUG
    /// `--demo 3,3,4` sets up that position and `--play` opens the game, for screenshots.
    private func applyLaunchArguments() {
        let arguments = CommandLine.arguments
        if let index = arguments.firstIndex(of: "--demo"), index + 1 < arguments.count {
            game.loadDemo(columns: arguments[index + 1].split(separator: ",").compactMap { Int($0) })
            isPlaying = true
        } else if arguments.contains("--play") {
            play()
        }
    }
    #endif
}
