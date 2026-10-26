// HomeView.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

struct HomeView: View {
    @Environment(GameViewModel.self) private var game
    @AppStorage(StorageKey.difficulty) private var difficulty: Difficulty = .easy
    @AppStorage(StorageKey.mode) private var mode: GameViewModel.Mode = .versusComputer
    @State private var isPlaying = false
    @State private var pendingDifficulty: Difficulty?

    var body: some View {
        NavigationStack {
            menu
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

    #if os(watchOS)
    private var menu: some View {
        ScrollView {
            VStack(spacing: 10) {
                title(discSize: 14, font: .title2.bold())
                playButton
                playersPicker.pickerStyle(.navigationLink)
                if mode == .versusComputer {
                    difficultyPicker.pickerStyle(.navigationLink)
                }
            }
        }
    }
    #else
    private var menu: some View {
        VStack(spacing: 28) {
            title(discSize: 36, font: .system(size: 64, weight: .bold, design: .rounded))
            playButton.controlSize(.large)
            playersPicker.pickerStyle(.segmented)
            if mode == .versusComputer {
                difficultyPicker.pickerStyle(.segmented)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
    #endif

    private var playButton: some View {
        Button(action: play) {
            Text("Play").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.discRed)
    }

    private var playersPicker: some View {
        Picker("Players", selection: $mode) {
            ForEach(GameViewModel.Mode.allCases) { Text($0.title).tag($0) }
        }
    }

    private var difficultyPicker: some View {
        Picker("Difficulty", selection: difficultySelection) {
            ForEach(Difficulty.allCases) { Text($0.title).tag($0) }
        }
    }

    private func title(discSize: CGFloat, font: Font) -> some View {
        HStack(spacing: discSize / 2) {
            DiscView(player: .red, size: discSize)
            Text("Vier").font(font)
            DiscView(player: .yellow, size: discSize)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Vier")
        .accessibilityAddTraits(.isHeader)
    }

    /// Changing difficulty with a game in progress asks first, because it ends that game.
    private var difficultySelection: Binding<Difficulty> {
        Binding {
            difficulty
        } set: { choice in
            if choice != difficulty && game.hasGameInProgress && game.mode == .versusComputer {
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
