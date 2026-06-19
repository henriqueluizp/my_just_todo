//
//  HapticsManager.swift
//  minimalist_todo
//
//  Thin wrapper around UIFeedbackGenerator. Centralising haptics lets us
//  honour a single user toggle and keeps call sites expressive
//  (`haptics.success()` instead of generator boilerplate).
//

import UIKit

@MainActor
final class HapticsManager {
    /// Mirrors the user's "Haptic feedback" setting. When false every call
    /// becomes a no-op.
    var isEnabled: Bool = true

    func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func warning() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
