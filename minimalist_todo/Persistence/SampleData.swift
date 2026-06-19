//
//  SampleData.swift
//  minimalist_todo
//
//  Seeds the default category set on first launch and provides rich sample
//  content for SwiftUI previews. Keeping this in one place means previews and
//  the real first-run experience never drift apart.
//

import CoreData

enum SampleData {
    /// The categories every new install starts with.
    static let defaultCategories: [(name: String, hex: String, symbol: String)] = [
        ("Personal", "#0A84FF", "person.fill"),
        ("Work", "#FF9F0A", "briefcase.fill"),
        ("Study", "#BF5AF2", "book.fill"),
        ("Health", "#30D158", "heart.fill"),
        ("Finance", "#40C8E0", "creditcard.fill")
    ]

    /// Inserts default categories if none exist yet. Idempotent.
    @discardableResult
    static func seedDefaultCategoriesIfNeeded(in context: NSManagedObjectContext) -> [TaskCategory] {
        let request = TaskCategory.fetchAllSorted()
        let existing = (try? context.fetch(request)) ?? []
        guard existing.isEmpty else { return existing }

        let created = defaultCategories.map { spec -> TaskCategory in
            let category = TaskCategory(context: context)
            category.id = UUID()
            category.name = spec.name
            category.colorHex = spec.hex
            category.symbol = spec.symbol
            category.createdAt = Date()
            return category
        }
        try? context.save()
        return created
    }

    /// Full sample dataset for previews: categories + a spread of tasks across
    /// yesterday, today and the coming days with varied priority/status.
    static func populate(in context: NSManagedObjectContext) {
        let categories = seedDefaultCategoriesIfNeeded(in: context)
        guard let work = categories.first(where: { $0.wrappedName == "Work" }),
              let health = categories.first(where: { $0.wrappedName == "Health" }) else { return }

        func make(_ title: String, _ details: String, due: Date,
                  priority: Priority, done: Bool, category: TaskCategory?) {
            let task = TaskItem(context: context)
            task.id = UUID()
            task.title = title
            task.details = details
            task.createdAt = Date()
            task.updatedAt = Date()
            task.dueDate = due
            task.priority = priority
            task.isCompleted = done
            task.completedAt = done ? Date() : nil
            task.category = category
            task.sortIndex = Date().timeIntervalSince1970
        }

        let today = Date()
        make("Design review", "Walk through the new onboarding flow with the team.",
             due: today, priority: .high, done: false, category: work)
        make("Morning run", "5km easy pace around the park.",
             due: today, priority: .medium, done: true, category: health)
        make("Reply to investor email", "Send the Q3 deck and follow-up notes.",
             due: today, priority: .high, done: false, category: work)
        make("Read 20 pages", "Continue the design systems book.",
             due: today.adding(days: 1), priority: .low, done: false, category: nil)
        make("Dentist appointment", "Annual check-up at 9:00.",
             due: today.adding(days: 2), priority: .medium, done: false, category: health)
        make("Plan weekend trip", "Book accommodation and check the weather.",
             due: today.adding(days: -1), priority: .low, done: false, category: nil)
    }
}
