//
//  TaskItem+Extensions.swift
//  minimalist_todo
//
//  Safe, expressive accessors over the auto-generated `TaskItem` managed
//  object. Core Data codegen makes object-type attributes optional in Swift
//  even when marked required, so these `wrapped*` helpers give the rest of the
//  app non-optional values and domain-level conveniences.
//

import CoreData
import SwiftUI

// Note: Core Data codegen already synthesises `Identifiable` conformance from
// the `id` attribute, enabling `sheet(item:)` / `navigationDestination(item:)`.

extension TaskItem {
    var wrappedID: UUID { id ?? UUID() }
    var wrappedTitle: String { title ?? "" }
    var wrappedDetails: String { details ?? "" }
    var wrappedCreatedAt: Date { createdAt ?? Date() }
    var wrappedUpdatedAt: Date { updatedAt ?? wrappedCreatedAt }

    var hasDetails: Bool { !wrappedDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    /// Effective accent for the card: explicit colour tag, else category
    /// colour, else priority colour.
    var displayColor: Color {
        if let tag = colorTag, !tag.isEmpty { return Color(hex: tag) }
        if let hex = category?.colorHex, !hex.isEmpty { return Color(hex: hex) }
        return priority.color
    }

    /// Overdue = has a due date in the past and not yet completed.
    var isOverdue: Bool {
        guard !isCompleted, let due = dueDate else { return false }
        return due.endOfDay < Date()
    }

    // MARK: - Mutations (callers are responsible for saving the context)

    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
        touch()
    }

    /// Stamps `updatedAt`. Call after any edit so "Last edited" stays honest.
    func touch() {
        updatedAt = Date()
    }

    // MARK: - Fetch helpers

    /// Active (non-trashed) tasks due on the given calendar day, newest sort
    /// order first. The predicate brackets the whole day to be DST-safe.
    static func fetchRequestForDay(_ day: Date) -> NSFetchRequest<TaskItem> {
        let request = NSFetchRequest<TaskItem>(entityName: "TaskItem")
        request.predicate = NSPredicate(
            format: "isTrashed == NO AND dueDate >= %@ AND dueDate <= %@",
            day.startOfDay as NSDate, day.endOfDay as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "sortIndex", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        return request
    }

    static func fetchAllActive() -> NSFetchRequest<TaskItem> {
        let request = NSFetchRequest<TaskItem>(entityName: "TaskItem")
        request.predicate = NSPredicate(format: "isTrashed == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        return request
    }
}
