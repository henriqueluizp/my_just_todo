//
//  TaskRepository.swift
//  minimalist_todo
//
//  The data-access boundary for tasks. View models depend on the
//  `TaskRepositoryProtocol` abstraction (Dependency Inversion), which makes
//  them testable with an in-memory store and keeps Core Data details out of
//  the presentation layer.
//

import CoreData
import Foundation

@MainActor
protocol TaskRepositoryProtocol {
    @discardableResult
    func create(title: String, details: String, dueDate: Date?, priority: Priority,
                category: TaskCategory?, colorTag: String?, reminderDate: Date?) -> TaskItem

    func toggleCompletion(_ task: TaskItem)
    func softDelete(_ task: TaskItem)
    func restore(_ task: TaskItem)
    func permanentlyDelete(_ task: TaskItem)
    @discardableResult func duplicate(_ task: TaskItem) -> TaskItem
    func emptyTrash()
    func move(_ task: TaskItem, to date: Date)
    func reorder(_ tasks: [TaskItem])
    func save()

    func tasks(on day: Date) -> [TaskItem]
    func allActive() -> [TaskItem]
    func trashed() -> [TaskItem]
    func search(_ query: String) -> [TaskItem]
    func daysWithTasks(inMonthOf date: Date) -> Set<Date>
}

@MainActor
final class CoreDataTaskRepository: TaskRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Create

    @discardableResult
    func create(title: String, details: String, dueDate: Date?, priority: Priority,
                category: TaskCategory?, colorTag: String?, reminderDate: Date?) -> TaskItem {
        let task = TaskItem(context: context)
        task.id = UUID()
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.details = details
        task.dueDate = dueDate
        task.priority = priority
        task.category = category
        task.colorTag = colorTag
        task.reminderDate = reminderDate
        task.isCompleted = false
        task.isTrashed = false
        task.createdAt = Date()
        task.updatedAt = Date()
        task.sortIndex = Date().timeIntervalSince1970
        save()
        return task
    }

    // MARK: - Mutations

    func toggleCompletion(_ task: TaskItem) {
        task.toggleCompletion()
        save()
    }

    func softDelete(_ task: TaskItem) {
        task.isTrashed = true
        task.trashedAt = Date()
        task.touch()
        save()
    }

    func restore(_ task: TaskItem) {
        task.isTrashed = false
        task.trashedAt = nil
        task.touch()
        save()
    }

    func permanentlyDelete(_ task: TaskItem) {
        context.delete(task)
        save()
    }

    @discardableResult
    func duplicate(_ task: TaskItem) -> TaskItem {
        let copy = TaskItem(context: context)
        copy.id = UUID()
        copy.title = task.wrappedTitle
        copy.details = task.details
        copy.dueDate = task.dueDate
        copy.priority = task.priority
        copy.category = task.category
        copy.colorTag = task.colorTag
        copy.reminderDate = task.reminderDate
        copy.isCompleted = false
        copy.isTrashed = false
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.sortIndex = task.sortIndex + 0.001
        save()
        return copy
    }

    func emptyTrash() {
        trashed().forEach(context.delete)
        save()
    }

    func move(_ task: TaskItem, to date: Date) {
        // Preserve the original time of day when shifting to a new date.
        let calendar = Calendar.current
        let timeComponents = task.dueDate.map {
            calendar.dateComponents([.hour, .minute], from: $0)
        } ?? DateComponents(hour: 9, minute: 0)
        task.dueDate = calendar.date(bySettingHour: timeComponents.hour ?? 9,
                                     minute: timeComponents.minute ?? 0,
                                     second: 0, of: date)
        task.touch()
        save()
    }

    func reorder(_ tasks: [TaskItem]) {
        for (index, task) in tasks.enumerated() {
            task.sortIndex = Double(index)
        }
        save()
    }

    func save() {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch {
            let nsError = error as NSError
            print("⚠️ Repository save failed: \(nsError.domain) \(nsError.code)")
            print("   userInfo: \(nsError.userInfo)")
            if let detailed = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                for d in detailed {
                    print("   • validation error \(d.code): \(d.userInfo)")
                }
            }
            context.rollback()
        }
    }

    // MARK: - Queries

    func tasks(on day: Date) -> [TaskItem] {
        (try? context.fetch(TaskItem.fetchRequestForDay(day))) ?? []
    }

    func allActive() -> [TaskItem] {
        (try? context.fetch(TaskItem.fetchAllActive())) ?? []
    }

    func trashed() -> [TaskItem] {
        let request = NSFetchRequest<TaskItem>(entityName: "TaskItem")
        request.predicate = NSPredicate(format: "isTrashed == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "trashedAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func search(_ query: String) -> [TaskItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let request = NSFetchRequest<TaskItem>(entityName: "TaskItem")
        request.predicate = NSPredicate(
            format: "isTrashed == NO AND (title CONTAINS[cd] %@ OR details CONTAINS[cd] %@)",
            trimmed, trimmed
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true)
        ]
        return (try? context.fetch(request)) ?? []
    }

    /// Distinct calendar days (start-of-day) in the visible month that contain
    /// at least one active task — drives the dots on the month grid.
    func daysWithTasks(inMonthOf date: Date) -> Set<Date> {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let request = NSFetchRequest<TaskItem>(entityName: "TaskItem")
        request.predicate = NSPredicate(
            format: "isTrashed == NO AND dueDate >= %@ AND dueDate < %@",
            interval.start as NSDate, interval.end as NSDate
        )
        request.propertiesToFetch = ["dueDate"]
        let tasks = (try? context.fetch(request)) ?? []
        return Set(tasks.compactMap { $0.dueDate?.startOfDay })
    }
}
