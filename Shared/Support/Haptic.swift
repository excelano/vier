// Haptic.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

/// The moments the game marks with a haptic. Each platform plays them in `Haptic+Play.swift`.
enum Haptic {
    case playerDrop
    case computerDrop
    case fullColumn
    case playerWin
    case computerWin
    case draw
}
