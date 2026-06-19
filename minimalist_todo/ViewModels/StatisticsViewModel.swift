//
//  StatisticsViewModel.swift
//  minimalist_todo
//
//  Computes the productivity dashboard: weekly/monthly completion rates, the
//  all-time completed total, the current streak and a 7-day completion bar
//  chart. Reads directly from the context (read-only) and refreshes on save.
//

import CoreData
import Observation
import SwiftUI

struct DayCompletion: Identifiable {
    let id = UUID()
    let date: Date
    let completed: Int
    let total: Int
    var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
}

@MainActor
@Observable
final class StatisticsViewModel {
    private(set) var weeklyRate: Double = 0
    private(set) var monthlyRate: Double = 0
    private(set) var totalCompleted: Int = 0
    private(set) var completedToday: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var last7Days: [DayCompletion] = []

    private let context: NSManagedObjectContext
    nonisolated(unsafe) private var saveObserver: NSObjectProtocol?

    init(context: NSManagedObjectContext) {
        self.context = context
        saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.recompute() }
        }
        recompute()
    }

    deinit {
        if let saveObserver { NotificationCenter.default.removeObserver(saveObserver) }
    }

    func recompute() {
        let all = fetchActive()
        let now = Date()

        totalCompleted = all.filter(\.isCompleted).count
        completedToday = all.filter { ($0.completedAt?.isToday ?? false) }.count

        weeklyRate = rate(for: all, in: .weekOfYear, of: now)
        monthlyRate = rate(for: all, in: .month, of: now)

        last7Days = buildLast7Days(from: all, now: now)
        currentStreak = computeStreak(from: all, now: now)
    }

    // MARK: - Calculations

    private func fetchActive() -> [TaskItem] {
        let request = NSFetchRequest<TaskItem>(entityName: "TaskItem")
        request.predicate = NSPredicate(format: "isTrashed == NO")
        return (try? context.fetch(request)) ?? []
    }

    /// Completion ratio of tasks *due* within the given calendar component.
    private func rate(for tasks: [TaskItem], in component: Calendar.Component, of date: Date) -> Double {
        let calendar = Calendar.current
        let scoped = tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, equalTo: date, toGranularity: component)
        }
        guard !scoped.isEmpty else { return 0 }
        return Double(scoped.filter(\.isCompleted).count) / Double(scoped.count)
    }

    private func buildLast7Days(from tasks: [TaskItem], now: Date) -> [DayCompletion] {
        (0..<7).reversed().map { offset -> DayCompletion in
            let day = now.adding(days: -offset).startOfDay
            let dayTasks = tasks.filter { $0.dueDate?.isSameDay(as: day) ?? false }
            return DayCompletion(date: day,
                                 completed: dayTasks.filter(\.isCompleted).count,
                                 total: dayTasks.count)
        }
    }

    /// Consecutive days (ending today or yesterday) with at least one task
    /// completed that day. Today not yet having a completion doesn't break a
    /// streak that ran through yesterday.
    private func computeStreak(from tasks: [TaskItem], now: Date) -> Int {
        let completionDays = Set(tasks.compactMap { $0.completedAt?.startOfDay })
        guard !completionDays.isEmpty else { return 0 }

        var streak = 0
        var cursor = now.startOfDay
        if !completionDays.contains(cursor) {
            cursor = cursor.adding(days: -1) // allow a streak that ended yesterday
            guard completionDays.contains(cursor) else { return 0 }
        }
        while completionDays.contains(cursor) {
            streak += 1
            cursor = cursor.adding(days: -1)
        }
        return streak
    }
}
