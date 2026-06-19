//
//  TaskDetailView.swift
//  minimalist_todo
//
//  Read-only detail screen for a task with an Edit entry point and inline
//  completion toggle. Surfaces every stored field including creation and
//  last-edited timestamps.
//

import SwiftUI

struct TaskDetailView: View {
    @ObservedObject var task: TaskItem
    var onEdit: () -> Void

    @Environment(\.container) private var container
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacingL) {
                header
                if task.hasDetails { detailsCard }
                metadataCard
                timestampsCard
            }
            .padding(theme.spacingM)
        }
        .background(theme.screenBackground)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: onEdit).fontWeight(.semibold)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            CheckCircle(isCompleted: task.isCompleted, color: task.displayColor, size: 32)
                .onTapGesture { container.taskRepository.toggleCompletion(task) }
            VStack(alignment: .leading, spacing: 6) {
                Text(task.wrappedTitle)
                    .font(theme.title)
                    .strikethrough(task.isCompleted, color: .secondary)
                if let due = task.dueDate {
                    Label(due.formatted(date: .complete, time: .shortened),
                          systemImage: "calendar")
                        .font(theme.callout)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
            }
            Spacer()
        }
        .padding(theme.spacingM)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusM))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes").font(theme.caption).foregroundStyle(.secondary)
            Text(task.wrappedDetails).font(theme.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacingM)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusM))
    }

    private var metadataCard: some View {
        VStack(spacing: 0) {
            row("Priority") { PriorityBadge(priority: task.priority) }
            if let category = task.category {
                Divider().padding(.leading, 16)
                row("Category") { CategoryChip(category: category) }
            }
            if let reminder = task.reminderDate {
                Divider().padding(.leading, 16)
                row("Reminder") {
                    Label(reminder.formatted(date: .abbreviated, time: .shortened),
                          systemImage: "bell.fill")
                        .font(theme.callout)
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusM))
    }

    private var timestampsCard: some View {
        VStack(spacing: 0) {
            row("Created") {
                Text(task.wrappedCreatedAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary).font(theme.callout)
            }
            Divider().padding(.leading, 16)
            row("Last edited") {
                Text(task.wrappedUpdatedAt.formatted(.relative(presentation: .named)))
                    .foregroundStyle(.secondary).font(theme.callout)
            }
            if let completed = task.completedAt {
                Divider().padding(.leading, 16)
                row("Completed") {
                    Text(completed.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.green).font(theme.callout)
                }
            }
        }
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusM))
    }

    private func row<Content: View>(_ label: String,
                                    @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label).font(theme.body)
            Spacer()
            content()
        }
        .padding(theme.spacingM)
    }
}
