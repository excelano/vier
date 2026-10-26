// Haptic+Play.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import UIKit

extension Haptic {
    @MainActor func play() {
        switch self {
        case .playerDrop: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .computerDrop: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .fullColumn: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .playerWin: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .computerWin: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .draw: UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
}
