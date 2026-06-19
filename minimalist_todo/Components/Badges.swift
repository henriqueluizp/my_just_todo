//
//  Badges.swift
//  minimalist_todo
//
//  Small presentational chips: priority flags and category tags. Grouped in
//  one file because they share the same compact pill styling.
//

import SwiftUI

struct PriorityBadge: View {
    let priority: Priority
    var body: some View {
        Label(priority.title, systemImage: priority.symbol)
            .font(.system(.caption2, design: .rounded).weight(.semibold))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.14), in: Capsule())
            .foregroundStyle(priority.color)
    }
}

struct CategoryChip: View {
    let category: TaskCategory
    var isSelected: Bool = false

    var body: some View {
        Label(category.displayName, systemImage: category.wrappedSymbol)
            .font(.system(.caption, design: .rounded).weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(category.color.opacity(isSelected ? 0.9 : 0.14))
            )
            .foregroundStyle(isSelected ? .white : category.color)
    }
}

/// Generic dot used to mark calendar days that contain tasks.
struct TaskDot: View {
    var color: Color
    var body: some View {
        Circle().fill(color).frame(width: 5, height: 5)
    }
}
