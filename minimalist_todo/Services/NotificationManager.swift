//
//  NotificationManager.swift
//  minimalist_todo
//
//  Wraps UNUserNotificationCenter for due-date reminders and the optional
//  daily agenda. Scheduling is keyed by the task's UUID so updates simply
//  replace the previous request.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let dailyAgendaIdentifier = "daily-agenda"

    private let center = UNUserNotificationCenter.current()

    /// Asks for permission. Returns whether it was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Task reminders

    /// Schedules (or reschedules) a reminder for a task. No-op when the task
    /// has no reminder date, is complete, or the date is in the past.
    func scheduleReminder(for task: TaskItem) {
        let id = task.wrappedID.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard let fireDate = task.reminderDate,
              !task.isCompleted,
              fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = task.wrappedTitle
        content.body = task.hasDetails ? task.wrappedDetails : "Scheduled task reminder"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancelReminder(for task: TaskItem) {
        center.removePendingNotificationRequests(withIdentifiers: [task.wrappedID.uuidString])
    }

    // MARK: - Daily agenda

    /// A single repeating notification at the user's chosen hour summarising
    /// the day ahead.
    func scheduleDailyAgenda(at components: DateComponents) {
        cancelDailyAgenda()
        let content = UNMutableNotificationContent()
        content.title = "Today's plan"
        content.body = "Open your planner to see what's on for today."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.dailyAgendaIdentifier,
                                         content: content, trigger: trigger))
    }

    func cancelDailyAgenda() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyAgendaIdentifier])
    }
}
