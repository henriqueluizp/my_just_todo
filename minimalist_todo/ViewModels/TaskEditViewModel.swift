//
//  TaskEditViewModel.swift
//  minimalist_todo
//
//  Backs both "create" and "edit" forms. Holds editable draft state, exposes
//  validation, and on save either inserts a new task or applies changes to the
//  existing one, then (re)schedules its reminder.
//

import CoreData
import Observation
import SwiftUI

@MainActor
@Observable
final class TaskEditViewModel {
    var title: String
    var details: String
    var dueDate: Date
    var hasDueDate: Bool
    var priority: Priority
    var category: TaskCategory?
    var colorTag: String?
    var hasReminder: Bool
    var reminderDate: Date

    let isEditing: Bool
    private(set) var categories: [TaskCategory] = []

    private let task: TaskItem?
    private let taskRepository: TaskRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let notifications: NotificationManager
    private let settings: SettingsStore
    private let haptics: HapticsManager

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// "Last edited" line shown only when editing an existing task.
    var lastEditedDescription: String? {
        guard let task, isEditing else { return nil }
        return task.wrappedUpdatedAt.formatted(.relative(presentation: .named))
    }

    init(task: TaskItem?, defaultDate: Date,
         taskRepository: TaskRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         notifications: NotificationManager,
         settings: SettingsStore,
         haptics: HapticsManager) {
        self.task = task
        self.isEditing = task != nil
        self.taskRepository = taskRepository
        self.categoryRepository = categoryRepository
        self.notifications = notifications
        self.settings = settings
        self.haptics = haptics

        let due = task?.dueDate ?? defaultDate.startOfDay.addingTimeInterval(9 * 3600)
        self.title = task?.wrappedTitle ?? ""
        self.details = task?.wrappedDetails ?? ""
        self.dueDate = due
        self.hasDueDate = task?.dueDate != nil || task == nil
        self.priority = task?.priority ?? .medium
        self.category = task?.category
        self.colorTag = task?.colorTag
        self.hasReminder = task?.reminderDate != nil
        self.reminderDate = task?.reminderDate ?? due

        self.categories = categoryRepository.all()
    }

    func save() {
        guard canSave else { return }
        haptics.success()
        let resolvedDue = hasDueDate ? dueDate : nil
        let resolvedReminder = (hasReminder && settings.notificationsEnabled) ? reminderDate : nil

        if let task {
            task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            task.details = details
            task.dueDate = resolvedDue
            task.priority = priority
            task.category = category
            task.colorTag = colorTag
            task.reminderDate = resolvedReminder
            task.touch()
            taskRepository.save()
            notifications.scheduleReminder(for: task)
        } else {
            let created = taskRepository.create(
                title: title, details: details, dueDate: resolvedDue,
                priority: priority, category: category, colorTag: colorTag,
                reminderDate: resolvedReminder)
            notifications.scheduleReminder(for: created)
        }
    }
}
