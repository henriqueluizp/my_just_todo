//
//  Theme.swift
//  minimalist_todo
//
//  Centralised design tokens. Every spacing value, corner radius, shadow and
//  font in the app references this type so the look stays consistent and is
//  trivial to retune. Injected through the environment as `\.theme`.
//

import SwiftUI

struct Theme {
    var accent: Color

    // MARK: Spacing (8-pt rhythm)
    let spacingXS: CGFloat = 4
    let spacingS: CGFloat = 8
    let spacingM: CGFloat = 16
    let spacingL: CGFloat = 24
    let spacingXL: CGFloat = 32

    // MARK: Corner radii
    let radiusS: CGFloat = 10
    let radiusM: CGFloat = 16
    let radiusL: CGFloat = 24

    // MARK: Surfaces
    /// Card background that adapts to light/dark automatically.
    var cardBackground: Color { Color(.secondarySystemGroupedBackground) }
    var screenBackground: Color { Color(.systemGroupedBackground) }
    var subtleFill: Color { Color(.tertiarySystemFill) }

    // MARK: Typography
    let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    let title = Font.system(.title2, design: .rounded).weight(.semibold)
    let headline = Font.system(.headline, design: .rounded)
    let body = Font.system(.body, design: .rounded)
    let callout = Font.system(.callout, design: .rounded)
    let caption = Font.system(.caption, design: .rounded)

    init(accent: Color = AccentPalette.blue.color) {
        self.accent = accent
    }
}

// MARK: - Environment plumbing

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Soft shadow modifier

extension View {
    /// The signature soft, low-opacity shadow used on cards and floating
    /// controls. Respects dark mode by staying subtle.
    func softShadow(radius: CGFloat = 14, y: CGFloat = 6, opacity: Double = 0.08) -> some View {
        shadow(color: Color.black.opacity(opacity), radius: radius, x: 0, y: y)
    }
}
