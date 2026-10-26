// VierApp.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

@main
struct VierApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var game = GameViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(game)
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                game.save()
            }
        }
    }
}
