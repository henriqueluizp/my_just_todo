//
//  AccentPalette.swift
//  minimalist_todo
//
//  The curated set of accent colours offered in Settings. Persisted by its
//  raw `id` so the choice survives relaunches and feeds the live `Theme`.
//

import SwiftUI

enum AccentPalette: String, CaseIterable, Identifiable {
    case blue
    case indigo
    case purple
    case pink
    case red
    case orange
    case green
    case teal
    case graphite

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .blue: Color(hex: "#0A84FF")
        case .indigo: Color(hex: "#5E5CE6")
        case .purple: Color(hex: "#BF5AF2")
        case .pink: Color(hex: "#FF2D78")
        case .red: Color(hex: "#FF453A")
        case .orange: Color(hex: "#FF9F0A")
        case .green: Color(hex: "#30D158")
        case .teal: Color(hex: "#40C8E0")
        case .graphite: Color(hex: "#8E8E93")
        }
    }
}
