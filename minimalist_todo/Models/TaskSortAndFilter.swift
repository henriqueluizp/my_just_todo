//
//  TaskSortAndFilter.swift
//  minimalist_todo
//
//  Value types describing how the task list is ordered and filtered. Kept
//  free of UI and persistence concerns so they can be unit-tested and reused
//  by the list, search and statistics view models.
//

import Foundation

enum TaskSortOption: String, CaseIterable, Identifiable {
    case dueDate
    case creationDate
    case priority
    case alphabetical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dueDate: String(localized: "Due date", bundle: .appLanguage)
        case .creationDate: String(localized: "Created", bundle: .appLanguage)
        case .priority: String(localized: "Priority", bundle: .appLanguage)
        case .alphabetical: String(localized: "A–Z", bundle: .appLanguage)
        }
    }

    var symbol: String {
        switch self {
        case .dueDate: "calendar"
        case .creationDate: "clock"
        case .priority: "flag"
        case .alphabetical: "textformat"
        }
    }
}

/// Completion status filter applied on top of the date/search scope.
enum TaskStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "All", bundle: .appLanguage)
        case .pending: String(localized: "Pending", bundle: .appLanguage)
        case .completed: String(localized: "Completed", bundle: .appLanguage)
        }
    }
}
