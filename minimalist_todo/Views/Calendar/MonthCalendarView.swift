//
//  MonthCalendarView.swift
//  minimalist_todo
//
//  Full month grid with weekday headers, leading padding for the first day's
//  weekday, task dots, today ring and selected-day fill. Month navigation via
//  chevrons; tapping a day selects it (and switches back to the day list).
//

import SwiftUI

struct MonthCalendarView: View {
    @Bindable var viewModel: CalendarViewModel
    @Environment(\.theme) private var theme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private var calendar: Calendar { .current }

    var body: some View {
        VStack(spacing: theme.spacingM) {
            header
            weekdayHeader
            grid
        }
        .padding(theme.spacingM)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusL))
        .softShadow()
        .padding(.horizontal, theme.spacingM)
    }

    private var header: some View {
        HStack {
            Text(viewModel.displayedMonth.monthYear)
                .font(theme.title)
            Spacer()
            Button { viewModel.step(months: -1) } label: {
                Image(systemName: "chevron.left").padding(8)
            }
            Button { viewModel.step(months: 1) } label: {
                Image(systemName: "chevron.right").padding(8)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.accent)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = date.isSameDay(as: viewModel.selectedDate)
        let isToday = date.isToday
        let hasTasks = viewModel.markedDays.contains(date.startOfDay)

        return VStack(spacing: 3) {
            Text(date.dayNumber)
                .font(.system(.callout, design: .rounded).weight(isToday ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : (isToday ? theme.accent : .primary))
            TaskDot(color: isSelected ? .white : theme.accent)
                .opacity(hasTasks ? 1 : 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background {
            if isSelected {
                Circle().fill(theme.accent).frame(width: 40, height: 40)
            } else if isToday {
                Circle().stroke(theme.accent.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.select(date)
            withAnimation(.snappy) { viewModel.viewMode = .day }
        }
        .accessibilityElement()
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(hasTasks ? "Has tasks" : "")
    }

    // MARK: - Day computation

    /// Weekday symbols rotated to match the user's first weekday.
    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// The grid cells: nil for leading blanks, then each day of the month.
    private var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: viewModel.displayedMonth)
        else { return [] }
        let firstDay = interval.start
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 30

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            cells.append(firstDay.adding(days: offset))
        }
        return cells
    }
}
