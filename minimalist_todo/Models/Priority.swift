//
//  Priority.swift
//  minimalist_todo
//
//  Task priority. Backed by an Int16 in Core Data (`priorityRaw`) so the
//  enum stays the single source of truth for colour, label and ordering.
//

import SwiftUI

enum Priority: Int16, CaseIterable, Identifiable, Comparable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int16 { rawValue }

    var title: String {
        switch self {
        case .low: String(localized: "Low", bundle: .appLanguage)
        case .medium: String(localized: "Medium", bundle: .appLanguage)
        case .high: String(localized: "High", bundle: .appLanguage)
        }
    }

    /// SF Symbol used in badges and pickers.
    var symbol: String {
        switch self {
        case .low: "flag"
        case .medium: "flag.fill"
        case .high: "flag.2.crossed.fill"
        }
    }

    var color: Color {
        switch self {
        case .low: .secondary
        case .medium: .blue
        case .high: .red
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
