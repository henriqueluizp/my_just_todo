//
//  TaskCategory+Extensions.swift
//  minimalist_todo
//
//  Conveniences over the generated `TaskCategory` managed object.
//

import CoreData
import SwiftUI

extension TaskCategory {
    var wrappedID: UUID { id ?? UUID() }
    var wrappedName: String { name ?? "" }
    var wrappedSymbol: String { symbol ?? "folder" }
    var color: Color { Color(hex: colorHex ?? "#0A84FF") }

    /// Names of the built-in default categories. Their display names are
    /// localized; user-created categories keep the name exactly as typed.
    private static let defaultNames: Set<String> =
        ["Personal", "Work", "Study", "Health", "Finance"]

    /// Localized name for display in the UI. Use `wrappedName` when editing the
    /// stored value.
    var displayName: String {
        let raw = wrappedName
        guard Self.defaultNames.contains(raw) else { return raw }
        return String(localized: String.LocalizationValue(raw), bundle: .appLanguage)
    }

    /// Count of active tasks in this category — shown next to the chip.
    var activeTaskCount: Int {
        let set = tasks as? Set<TaskItem> ?? []
        return set.filter { !$0.isTrashed }.count
    }

    static func fetchAllSorted() -> NSFetchRequest<TaskCategory> {
        let request = NSFetchRequest<TaskCategory>(entityName: "TaskCategory")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return request
    }
}
