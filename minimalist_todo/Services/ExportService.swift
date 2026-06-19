//
//  ExportService.swift
//  minimalist_todo
//
//  JSON backup & restore. Tasks and categories are flattened into Codable
//  DTOs (category referenced by id) so the file is portable and human
//  readable. Restore is additive and de-duplicates by UUID.
//

import CoreData
import Foundation

struct TaskDTO: Codable {
    var id: UUID
    var title: String
    var details: String?
    var createdAt: Date
    var updatedAt: Date
    var dueDate: Date?
    var completedAt: Date?
    var reminderDate: Date?
    var isCompleted: Bool
    var priority: Int16
    var colorTag: String?
    var categoryID: UUID?
}

struct CategoryDTO: Codable {
    var id: UUID
    var name: String
    var colorHex: String
    var symbol: String
    var createdAt: Date
}

struct BackupDTO: Codable {
    var version: Int = 1
    var exportedAt: Date = Date()
    var categories: [CategoryDTO]
    var tasks: [TaskDTO]
}

@MainActor
enum ExportService {
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Serialises all non-trashed content to pretty-printed JSON data.
    static func exportData(context: NSManagedObjectContext) throws -> Data {
        let categories = (try? context.fetch(TaskCategory.fetchAllSorted())) ?? []
        let tasks = (try? context.fetch(TaskItem.fetchAllActive())) ?? []

        let backup = BackupDTO(
            categories: categories.map {
                CategoryDTO(id: $0.wrappedID, name: $0.wrappedName,
                            colorHex: $0.colorHex ?? "#0A84FF",
                            symbol: $0.wrappedSymbol, createdAt: $0.createdAt ?? Date())
            },
            tasks: tasks.map {
                TaskDTO(id: $0.wrappedID, title: $0.wrappedTitle, details: $0.details,
                        createdAt: $0.wrappedCreatedAt, updatedAt: $0.wrappedUpdatedAt,
                        dueDate: $0.dueDate, completedAt: $0.completedAt,
                        reminderDate: $0.reminderDate, isCompleted: $0.isCompleted,
                        priority: $0.priorityRaw, colorTag: $0.colorTag,
                        categoryID: $0.category?.wrappedID)
            }
        )
        return try encoder.encode(backup)
    }

    /// Writes the export to a temporary file and returns its URL (for the
    /// share sheet).
    static func exportToTemporaryFile(context: NSManagedObjectContext) throws -> URL {
        let data = try exportData(context: context)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MinimalistTodo-Backup.json")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Restores from backup data. Existing items with the same UUID are skipped
    /// so the operation is safe to run repeatedly.
    static func restore(from data: Data, context: NSManagedObjectContext) throws {
        let backup = try decoder.decode(BackupDTO.self, from: data)

        var categoryByID: [UUID: TaskCategory] = [:]
        for dto in backup.categories {
            if let existing = fetchCategory(id: dto.id, context: context) {
                categoryByID[dto.id] = existing
                continue
            }
            let category = TaskCategory(context: context)
            category.id = dto.id
            category.name = dto.name
            category.colorHex = dto.colorHex
            category.symbol = dto.symbol
            category.createdAt = dto.createdAt
            categoryByID[dto.id] = category
        }

        for dto in backup.tasks where fetchTask(id: dto.id, context: context) == nil {
            let task = TaskItem(context: context)
            task.id = dto.id
            task.title = dto.title
            task.details = dto.details
            task.createdAt = dto.createdAt
            task.updatedAt = dto.updatedAt
            task.dueDate = dto.dueDate
            task.completedAt = dto.completedAt
            task.reminderDate = dto.reminderDate
            task.isCompleted = dto.isCompleted
            task.priorityRaw = dto.priority
            task.colorTag = dto.colorTag
            task.isTrashed = false
            task.sortIndex = dto.createdAt.timeIntervalSince1970
            if let cid = dto.categoryID { task.category = categoryByID[cid] }
        }

        if context.hasChanges { try context.save() }
    }

    // MARK: - Helpers

    private static func fetchCategory(id: UUID, context: NSManagedObjectContext) -> TaskCategory? {
        let request = NSFetchRequest<TaskCategory>(entityName: "TaskCategory")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private static func fetchTask(id: UUID, context: NSManagedObjectContext) -> TaskItem? {
        let request = NSFetchRequest<TaskItem>(entityName: "TaskItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
