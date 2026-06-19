//
//  TaskEditView.swift
//  minimalist_todo
//
//  The create/edit form. A clean grouped form covering every editable field
//  from the spec: title, description, due date, priority, category, colour tag
//  and reminder. Validation gates the Save button.
//

import SwiftUI

struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var viewModel: TaskEditViewModel
    @FocusState private var titleFocused: Bool

    init(viewModel: TaskEditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let colorOptions = AccentPalette.allCases.map { $0.color.hexString }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                schedulingSection
                organisationSection
                if viewModel.hasDueDate { reminderSection }
                if let edited = viewModel.lastEditedDescription {
                    Section {
                        Text("Last edited \(edited)")
                            .font(theme.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.save(); dismiss() }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.canSave)
                }
            }
            .onAppear { if !viewModel.isEditing { titleFocused = true } }
        }
        .presentationDragIndicator(.visible)
    }

    private var detailsSection: some View {
        Section {
            TextField("Title", text: $viewModel.title, axis: .vertical)
                .font(theme.headline)
                .focused($titleFocused)
            TextField("Notes", text: $viewModel.details, axis: .vertical)
                .lineLimit(3...8)
                .foregroundStyle(.secondary)
        }
    }

    private var schedulingSection: some View {
        Section("Schedule") {
            Toggle(isOn: $viewModel.hasDueDate.animation(.snappy)) {
                Label("Due date", systemImage: "calendar")
            }
            if viewModel.hasDueDate {
                DatePicker("Date", selection: $viewModel.dueDate,
                           displayedComponents: [.date, .hourAndMinute])
            }
        }
    }

    private var organisationSection: some View {
        Section("Organise") {
            Picker(selection: $viewModel.priority) {
                ForEach(Priority.allCases) { priority in
                    Label(priority.title, systemImage: priority.symbol).tag(priority)
                }
            } label: {
                Label("Priority", systemImage: "flag")
            }

            Picker(selection: $viewModel.category) {
                Text("None").tag(TaskCategory?.none)
                ForEach(viewModel.categories) { category in
                    Label(category.displayName, systemImage: category.wrappedSymbol)
                        .tag(TaskCategory?.some(category))
                }
            } label: {
                Label("Category", systemImage: "folder")
            }

            colorTagPicker
        }
    }

    private var colorTagPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Colour tag", systemImage: "paintpalette")
            HStack(spacing: 12) {
                clearTagButton
                ForEach(colorOptions, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 26, height: 26)
                        .overlay {
                            if viewModel.colorTag == hex {
                                Circle().stroke(.primary, lineWidth: 2).padding(-3)
                            }
                        }
                        .onTapGesture { viewModel.colorTag = hex }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var clearTagButton: some View {
        Image(systemName: "slash.circle")
            .font(.system(size: 22))
            .foregroundStyle(.secondary)
            .frame(width: 26, height: 26)
            .overlay {
                if viewModel.colorTag == nil {
                    Circle().stroke(.primary, lineWidth: 2).padding(-3)
                }
            }
            .onTapGesture { viewModel.colorTag = nil }
    }

    private var reminderSection: some View {
        Section("Reminder") {
            Toggle(isOn: $viewModel.hasReminder.animation(.snappy)) {
                Label("Remind me", systemImage: "bell")
            }
            if viewModel.hasReminder {
                DatePicker("Time", selection: $viewModel.reminderDate,
                           displayedComponents: [.date, .hourAndMinute])
            }
        }
    }
}
