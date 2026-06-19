//
//  CategoryRepository.swift
//  minimalist_todo
//
//  Data-access boundary for categories. Mirrors TaskRepository so view models
//  can be unit-tested against a protocol.
//

import CoreData
import Foundation

@MainActor
protocol CategoryRepositoryProtocol {
    @discardableResult
    func create(name: String, colorHex: String, symbol: String) -> TaskCategory
    func update(_ category: TaskCategory, name: String, colorHex: String, symbol: String)
    func delete(_ category: TaskCategory)
    func all() -> [TaskCategory]
    func save()
}

@MainActor
final class CoreDataCategoryRepository: CategoryRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    @discardableResult
    func create(name: String, colorHex: String, symbol: String) -> TaskCategory {
        let category = TaskCategory(context: context)
        category.id = UUID()
        category.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        category.colorHex = colorHex
        category.symbol = symbol
        category.createdAt = Date()
        save()
        return category
    }

    func update(_ category: TaskCategory, name: String, colorHex: String, symbol: String) {
        category.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        category.colorHex = colorHex
        category.symbol = symbol
        save()
    }

    func delete(_ category: TaskCategory) {
        // Relationship deletion rule is Nullify, so tasks are kept and simply
        // become uncategorised.
        context.delete(category)
        save()
    }

    func all() -> [TaskCategory] {
        (try? context.fetch(TaskCategory.fetchAllSorted())) ?? []
    }

    func save() {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { assertionFailure("Category save failed: \(error)") }
    }
}
