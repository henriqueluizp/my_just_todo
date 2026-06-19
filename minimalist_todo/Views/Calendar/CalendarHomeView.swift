//
//  CalendarHomeView.swift
//  minimalist_todo
//
//  The home planner. Combines a custom search + filter bar (same row, 12pt
//  gap), the one-line day header, daily-progress ring, the day/week/month
//  switcher, and the task list (swipe actions, drag reorder, long-press context
//  menu) plus a floating quick-add button.
//

import SwiftUI

struct CalendarHomeView: View {
    @Environment(\.container) private var container
    @Environment(\.theme) private var theme

    @State private var viewModel: CalendarViewModel
    @State private var editingTask: TaskItem?
    @State private var detailTask: TaskItem?
    @State private var isPresentingNewTask = false

    init(viewModel: CalendarViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .background(theme.screenBackground)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .overlay(alignment: .bottomTrailing) { quickAddButton }
                .overlay(alignment: .bottom) { undoBanner }
                .navigationDestination(item: $detailTask) { task in
                    TaskDetailView(task: task) { editingTask = task }
                }
                .sheet(item: $editingTask) { task in
                    TaskEditView(viewModel: container.makeEditViewModel(
                        editing: task, defaultDate: viewModel.selectedDate))
                }
                .sheet(isPresented: $isPresentingNewTask) {
                    TaskEditView(viewModel: container.makeEditViewModel(
                        editing: nil, defaultDate: viewModel.selectedDate))
                }
        }
    }

    // MARK: - Layout

    /// Fixed header (re-renders reliably on state changes such as the daily
    /// percentage) above a List that only holds the task rows.
    private var content: some View {
        VStack(spacing: 0) {
            headerArea
            taskList
        }
    }

    private var headerArea: some View {
        VStack(spacing: 12) {
            searchAndFilterBar
                .padding(.horizontal, 16)

            if !viewModel.isSearching {
                dayHeader
                    .padding(.horizontal, 16)
                viewModeSwitcher
                    .padding(.horizontal, 16)
                calendarSection
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(theme.screenBackground)
        .animation(.snappy, value: viewModel.viewMode)
        .animation(.snappy, value: viewModel.isSearching)
    }

    private var taskList: some View {
        List {
            if viewModel.isSearching {
                searchResultsSection
            } else {
                taskSections
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .animation(.snappy, value: viewModel.dayTasks.count)
    }

    // MARK: - Search + filter bar (same row, 12pt gap)

    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search tasks", text: $viewModel.searchText)
                    .submitLabel(.search)
                if viewModel.isSearching {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(theme.subtleFill, in: RoundedRectangle(cornerRadius: 12))

            Menu {
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(TaskSortOption.allCases) { option in
                        Label(option.title, systemImage: option.symbol).tag(option)
                    }
                }
                Picker("Show", selection: $viewModel.statusFilter) {
                    ForEach(TaskStatusFilter.allCases) { Text($0.title).tag($0) }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.title3)
                    .foregroundStyle(theme.accent)
                    .frame(width: 44, height: 44)
                    .background(theme.subtleFill, in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Filter and sort")
        }
    }

    // MARK: - Day header (one line)

    private var dayHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedDate.relativeDayDescription)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.accent)
                Text(viewModel.selectedDate.compactDayHeader)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer()
            if viewModel.totalCount > 0 {
                ProgressRingView(progress: viewModel.completionFraction, color: theme.accent)
            }
        }
        
    }

    private var viewModeSwitcher: some View {
        Picker("View", selection: $viewModel.viewMode) {
            ForEach(CalendarViewMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var calendarSection: some View {
        switch viewModel.viewMode {
        case .day, .week:
            WeekStripView(viewModel: viewModel)
                .transition(.opacity)
        case .month:
            MonthCalendarView(viewModel: viewModel)
                .transition(.opacity)
        }
    }

    // MARK: - Task sections

    @ViewBuilder
    private var taskSections: some View {
        if viewModel.dayTasks.isEmpty {
            emptyState
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else {
            if !viewModel.pendingTasks.isEmpty {
                Section {
                    ForEach(viewModel.pendingTasks) { taskRow($0) }
                        .onMove(perform: viewModel.reorder)
                } header: {
                    sectionHeader("To do", count: viewModel.remainingCount)
                }
            }
            if !viewModel.completedTasks.isEmpty {
                Section {
                    ForEach(viewModel.completedTasks) { taskRow($0) }
                } header: {
                    sectionHeader("Completed", count: viewModel.completedCount)
                }
            }
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        if viewModel.searchResults.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "No results",
                           message: "No tasks match “\(viewModel.searchText)”.",
                           tint: theme.accent)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else {
            Section {
                ForEach(viewModel.searchResults) { taskRow($0) }
            } header: {
                sectionHeader("Results", count: viewModel.searchResults.count)
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        TaskCardView(task: task,
                     onToggle: { viewModel.toggle(task) },
                     onTap: { detailTask = task })
            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { viewModel.delete(task) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button { viewModel.toggle(task) } label: {
                    Label(task.isCompleted ? "Reopen" : "Done",
                          systemImage: task.isCompleted ? "arrow.uturn.left" : "checkmark")
                }
                .tint(.green)
            }
            .contextMenu { contextMenu(for: task) }
    }

    @ViewBuilder
    private func contextMenu(for task: TaskItem) -> some View {
        Button { editingTask = task } label: { Label("Edit", systemImage: "pencil") }
        Button { viewModel.toggle(task) } label: {
            Label(task.isCompleted ? "Mark as pending" : "Mark as done",
                  systemImage: task.isCompleted ? "circle" : "checkmark.circle")
        }
        Button { viewModel.duplicate(task) } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        Menu {
            Button("Today") { viewModel.move(task, to: Date()) }
            Button("Tomorrow") { viewModel.move(task, to: Date().adding(days: 1)) }
            Button("Next week") { viewModel.move(task, to: Date().adding(days: 7)) }
        } label: {
            Label("Move to", systemImage: "calendar")
        }
        Divider()
        Button(role: .destructive) { viewModel.delete(task) } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func sectionHeader(_ title: LocalizedStringKey, count: Int) -> some View {
        HStack {
            Text(title).font(theme.headline)
            Text("\(count)")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(theme.subtleFill, in: Capsule())
            Spacer()
        }
        .textCase(nil)
        .padding(.top, 4)
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: viewModel.selectedDate.isToday ? "sparkles" : "calendar",
            title: viewModel.selectedDate.isToday ? "Your day is clear" : "Nothing planned",
            message: viewModel.selectedDate.isToday
                ? "A fresh start. Add your first task and make today count."
                : "No tasks for this day yet. Tap + to plan ahead.",
            tint: theme.accent,
            actionTitle: "Add a task",
            action: { isPresentingNewTask = true })
        .frame(minHeight: 280)
    }

    // MARK: - Floating quick add

    private var quickAddButton: some View {
        Button {
            container.haptics.impact(.medium)
            isPresentingNewTask = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(theme.accent.gradient, in: Circle())
                .softShadow(radius: 16, y: 8, opacity: 0.25)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .accessibilityLabel("Add task")
    }

    // MARK: - Undo banner

    @ViewBuilder
    private var undoBanner: some View {
        if viewModel.recentlyDeleted != nil {
            HStack {
                Label("Task deleted", systemImage: "trash")
                    .font(theme.callout)
                Spacer()
                Button("Undo") { viewModel.undoDelete() }
                    .font(.system(.callout, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.accent)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .softShadow()
            .padding(.horizontal, 24)
            .padding(.bottom, 96)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.snappy) { viewModel.clearUndo() }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !viewModel.isViewingToday {
                Button("Today") { viewModel.goToToday() }
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
        }
    }
}
