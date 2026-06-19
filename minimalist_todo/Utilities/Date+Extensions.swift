//
//  Date+Extensions.swift
//  minimalist_todo
//
//  Calendar maths used throughout the planner. All helpers route through a
//  single `Calendar.current` so the app respects the user's locale and
//  first-weekday preference.
//

import Foundation

extension Date {
    /// Midnight at the start of the day in the current calendar.
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    /// The last representable instant of the day (23:59:59.999...).
    var endOfDay: Date {
        let start = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        return start.addingTimeInterval(-0.001)
    }

    var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: self)?.start ?? startOfDay
    }

    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? startOfDay
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isInPast: Bool { self < Date() }

    /// Number of whole days between two calendar days (ignores time of day).
    func dayCount(to other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startOfDay, to: other.startOfDay).day ?? 0
    }

    // MARK: - Formatting

    /// e.g. "Thursday, 18 June" — used in the large day header.
    var longDayHeader: String {
        formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.app))
    }

    /// One-line header in the order day, weekday, month — e.g.
    /// "18, quinta-feira, junho". Designed to fit a single line.
    var compactDayHeader: String {
        let day = formatted(.dateTime.day().locale(.app))
        let weekday = formatted(.dateTime.weekday(.wide).locale(.app))
        let month = formatted(.dateTime.month(.wide).locale(.app))
        return "\(day), \(weekday), \(month)"
    }

    /// e.g. "June 2026" — month navigation title.
    var monthYear: String {
        formatted(.dateTime.month(.wide).year().locale(.app))
    }

    /// Single uppercase weekday initial for the week strip, e.g. "M".
    var weekdayNarrow: String {
        formatted(.dateTime.weekday(.narrow).locale(.app))
    }

    var dayNumber: String {
        formatted(.dateTime.day().locale(.app))
    }

    /// Relative, human description for due dates: "Today", "Tomorrow",
    /// "Yesterday", or an absolute short date.
    var relativeDayDescription: String {
        if isToday { return String(localized: "Today", bundle: .appLanguage) }
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(self) { return String(localized: "Tomorrow", bundle: .appLanguage) }
        if calendar.isDateInYesterday(self) { return String(localized: "Yesterday", bundle: .appLanguage) }
        return formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(.app))
    }
}
