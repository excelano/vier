// Haptic+Play.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import WatchKit

extension Haptic {
    func play() {
        WKInterfaceDevice.current().play(type)
    }

    private var type: WKHapticType {
        switch self {
        case .playerDrop: .click
        case .computerDrop: .directionDown
        case .fullColumn: .failure
        case .playerWin: .success
        case .computerWin: .retry
        case .draw: .notification
        }
    }
}
