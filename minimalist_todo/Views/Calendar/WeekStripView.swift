//
//  WeekStripView.swift
//  minimalist_todo
//
//  A horizontally paging strip of weeks. Each page is the seven days of a
//  week; swiping moves between weeks (effectively infinite via a wide tag
//  range). Selecting a day updates the view model; today and the selected day
//  get distinct treatments and days containing tasks show a dot.
//

import SwiftUI

struct WeekStripView: View {
    @Bindable var viewModel: CalendarViewModel
    @Environment(\.theme) private var theme

    /// Reference week (today). Page tag = whole weeks from this reference.
    private let referenceWeek = Date().startOfWeek
    private let range = -260...260   // ~5 years each direction

    @State private var weekOffset = 0

    var body: some View {
        TabView(selection: $weekOffset) {
            ForEach(range, id: \.self) { offset in
                weekRow(for: offset).tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 70)
        .onChange(of: viewModel.selectedDate) { _, _ in syncOffset() }
        .onAppear(perform: syncOffset)
    }

    private func weekRow(for offset: Int) -> some View {
        let weekStart = referenceWeek.adding(days: offset * 7)
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                dayCell(weekStart.adding(days: index))
            }
        }
        .padding(.horizontal, theme.spacingM)
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = date.isSameDay(as: viewModel.selectedDate)
        let isToday = date.isToday
        let hasTasks = viewModel.markedDays.contains(date.startOfDay)

        return VStack(spacing: 6) {
            Text(date.weekdayNarrow)
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundStyle(.secondary)

            Text(date.dayNumber)
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(isSelected ? .white : (isToday ? theme.accent : .primary))
                .frame(width: 36, height: 36)
                .background {
                    if isSelected {
                        Circle().fill(theme.accent)
                    } else if isToday {
                        Circle().stroke(theme.accent, lineWidth: 1.5)
                    }
                }

            TaskDot(color: theme.accent)
                .opacity(hasTasks && !isSelected ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.select(date) }
        .accessibilityElement()
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func syncOffset() {
        let weeks = referenceWeek.dayCount(to: viewModel.selectedDate.startOfWeek) / 7
        if weeks != weekOffset {
            withAnimation(.snappy) { weekOffset = weeks }
        }
    }
}
