//
//  CalendarViewModel.swift
//  minimalist_todo
//
//  Drives the home planner: the selected date, the day/week/month view mode,
//  the task list for the chosen day, search, filtering, sorting and the
//  undo-able delete. Depends only on the repository protocol and settings so
//  it is fully testable. Reloads whenever the store saves so edits made
//  elsewhere (detail screen, notifications) stay reflected.
//

import CoreData
import Observation
import SwiftUI

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day, week, month
    var id: String { rawValue }
    var title: String {
        switch self {
        case .day: String(localized: "Day", bundle: .appLanguage)
        case .week: String(localized: "Week", bundle: .appLanguage)
        case .month: String(localized: "Month", bundle: .appLanguage)
        }
    }
}

@MainActor
@Observable
final class CalendarViewModel {
    // Navigation state
    var selectedDate: Date = Date().startOfDay { didSet { reload() } }
    var displayedMonth: Date = Date().startOfMonth { didSet { reloadMarkers() } }
    var viewMode: CalendarViewMode = .day

    // Filtering / sorting / search
    var searchText: String = "" { didSet { reloadSearch() } }
    var statusFilter: TaskStatusFilter = .all { didSet { reload() } }
    var selectedCategoryFilter: TaskCategory? { didSet { reload() } }
    var sortOption: TaskSortOption { didSet { settings.sortOption = sortOption; reload() } }

    // Outputs
    private(set) var dayTasks: [TaskItem] = []
    private(set) var searchResults: [TaskItem] = []
    private(set) var markedDays: Set<Date> = []

    // Undo support
    private(set) var recentlyDeleted: TaskItem?

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let repository: TaskRepositoryProtocol
    private let settings: SettingsStore
    private let haptics: HapticsManager
    nonisolated(unsafe) private var saveObserver: NSObjectProtocol?

    init(repository: TaskRepositoryProtocol, settings: SettingsStore, haptics: HapticsManager) {
        self.repository = repository
        self.settings = settings
        self.haptics = haptics
        self.sortOption = settings.sortOption

        saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshAll() }
        }
        refreshAll()
    }

    deinit {
        if let saveObserver { NotificationCenter.default.removeObserver(saveObserver) }
    }

    // MARK: - Daily progress (productivity summary)

    var totalCount: Int { dayTasks.count }
    var completedCount: Int { dayTasks.filter(\.isCompleted).count }
    var remainingCount: Int { totalCount - completedCount }
    var completionFraction: Double {
        totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount)
    }

    /// Tasks split for the "Today's Focus" / sectioned presentation.
    var pendingTasks: [TaskItem] { dayTasks.filter { !$0.isCompleted } }
    var completedTasks: [TaskItem] { dayTasks.filter(\.isCompleted) }

    // MARK: - Navigation actions

    func goToToday() {
        haptics.selection()
        withAnimation(.snappy) {
            selectedDate = Date().startOfDay
            displayedMonth = Date().startOfMonth
        }
    }

    func select(_ date: Date) {
        haptics.selection()
        selectedDate = date.startOfDay
        if !Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = date.startOfMonth
        }
    }

    func step(days: Int) {
        withAnimation(.snappy) { selectedDate = selectedDate.adding(days: days) }
    }

    func step(months: Int) {
        withAnimation(.snappy) { displayedMonth = displayedMonth.adding(months: months) }
    }

    var isViewingToday: Bool { selectedDate.isToday }

    // MARK: - Task actions

    func toggle(_ task: TaskItem) {
        if !task.isCompleted { haptics.success() } else { haptics.tap() }
        repository.toggleCompletion(task)
        withAnimation(.snappy) { refreshAll() }
    }

    func delete(_ task: TaskItem) {
        haptics.warning()
        recentlyDeleted = task
        repository.softDelete(task)
        withAnimation(.snappy) { refreshAll() }
    }

    func undoDelete() {
        guard let task = recentlyDeleted else { return }
        haptics.tap()
        repository.restore(task)
        recentlyDeleted = nil
        withAnimation(.snappy) { refreshAll() }
    }

    func clearUndo() { recentlyDeleted = nil }

    func duplicate(_ task: TaskItem) {
        haptics.tap()
        repository.duplicate(task)
        withAnimation(.snappy) { refreshAll() }
    }

    func move(_ task: TaskItem, to date: Date) {
        haptics.selection()
        repository.move(task, to: date)
        withAnimation(.snappy) { refreshAll() }
    }

    func reorder(from source: IndexSet, to destination: Int) {
        var items = pendingTasks
        items.move(fromOffsets: source, toOffset: destination)
        repository.reorder(items)
    }

    // MARK: - Loading

    private func refreshAll() {
        reload()
        reloadMarkers()
        if isSearching { reloadSearch() }
    }

    private func reload() {
        var tasks = repository.tasks(on: selectedDate)
        tasks = applyFilters(to: tasks)
        dayTasks = applySort(to: tasks)
    }

    private func reloadMarkers() {
        markedDays = repository.daysWithTasks(inMonthOf: displayedMonth)
    }

    private func reloadSearch() {
        searchResults = applySort(to: repository.search(searchText))
    }

    private func applyFilters(to tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter { task in
            switch statusFilter {
            case .all: break
            case .pending: if task.isCompleted { return false }
            case .completed: if !task.isCompleted { return false }
            }
            if let category = selectedCategoryFilter, task.category != category { return false }
            return true
        }
    }

    private func applySort(to tasks: [TaskItem]) -> [TaskItem] {
        switch sortOption {
        case .dueDate:
            return tasks.sorted {
                ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
        case .creationDate:
            return tasks.sorted { $0.wrappedCreatedAt < $1.wrappedCreatedAt }
        case .priority:
            return tasks.sorted { $0.priority > $1.priority }
        case .alphabetical:
            return tasks.sorted {
                $0.wrappedTitle.localizedCaseInsensitiveCompare($1.wrappedTitle) == .orderedAscending
            }
        }
    }
}
