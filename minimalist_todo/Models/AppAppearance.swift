//
//  AppAppearance.swift
//  minimalist_todo
//
//  User-selectable colour scheme. Maps to SwiftUI's `ColorScheme?` where
//  `nil` means "follow the system".
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: String(localized: "System", bundle: .appLanguage)
        case .light: String(localized: "Light", bundle: .appLanguage)
        case .dark: String(localized: "Dark", bundle: .appLanguage)
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
