//
//  TaskCardView.swift
//  minimalist_todo
//
//  The premium task card: a soft, rounded surface with a colour accent rail,
//  an animated completion circle, title/details and a metadata footer
//  (priority, category, due time, overdue flag). Purely presentational — all
//  actions are delegated to the parent via closures.
//

import SwiftUI

struct TaskCardView: View {
    // Observing the managed object directly means the card re-renders the
    // instant any of its properties change (e.g. completion toggled), without
    // waiting for the list to reload.
    @ObservedObject var task: TaskItem
    var onToggle: () -> Void
    var onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            // Colour accent rail
            RoundedRectangle(cornerRadius: 2)
                .fill(task.displayColor)
                .frame(width: 4)
                .padding(.vertical, 14)
                .opacity(task.isCompleted ? 0.35 : 1)

            HStack(alignment: .top, spacing: 12) {
                CheckCircle(isCompleted: task.isCompleted, color: task.displayColor)
                    .onTapGesture(perform: onToggle)
                    .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
                    .accessibilityAddTraits(.isButton)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.wrappedTitle)
                        .font(theme.headline)
                        .strikethrough(task.isCompleted, color: .secondary)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .lineLimit(2)

                    if task.hasDetails {
                        Text(task.wrappedDetails)
                            .font(theme.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    footer
                }
                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusM))
        .softShadow()
        .opacity(task.isCompleted ? 0.85 : 1)
        .contentShape(RoundedRectangle(cornerRadius: theme.radiusM))
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to open details")
    }

    @ViewBuilder
    private var footer: some View {
        let hasMeta = task.priority != .medium || task.category != nil
            || task.dueDate != nil || task.isOverdue
        if hasMeta {
            HStack(spacing: 8) {
                if task.priority != .medium {
                    PriorityBadge(priority: task.priority)
                }
                if let category = task.category {
                    Label(category.displayName, systemImage: category.wrappedSymbol)
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundStyle(category.color)
                }
                if let due = task.dueDate {
                    Label(due.formatted(date: .omitted, time: .shortened),
                          systemImage: "clock")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
                if task.isOverdue {
                    Text("Overdue")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(.red)
                }
            }
            .padding(.top, 2)
        }
    }
}
