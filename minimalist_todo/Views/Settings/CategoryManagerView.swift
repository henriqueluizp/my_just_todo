//
//  CategoryManagerView.swift
//  minimalist_todo
//
//  Create, edit and delete categories. Each row shows its colour and symbol;
//  an editor sheet handles both add and edit.
//

import SwiftUI

struct CategoryManagerView: View {
    @Environment(\.theme) private var theme
    @State private var viewModel: CategoryViewModel
    @State private var editing: TaskCategory?
    @State private var isCreating = false

    init(viewModel: CategoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.categories) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.wrappedSymbol)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(category.color.gradient, in: RoundedRectangle(cornerRadius: 9))
                    Text(category.displayName).font(theme.body)
                    Spacer()
                    Text("\(category.activeTaskCount)")
                        .font(theme.caption).foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = category }
            }
            .onDelete { viewModel.delete(at: $0) }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isCreating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isCreating) {
            CategoryEditorView(viewModel: viewModel, category: nil)
        }
        .sheet(item: $editing) { category in
            CategoryEditorView(viewModel: viewModel, category: category)
        }
        .overlay {
            if viewModel.categories.isEmpty {
                EmptyStateView(symbol: "folder.badge.plus",
                               title: "No categories",
                               message: "Group tasks by context — Work, Health, Study and more.",
                               tint: theme.accent,
                               actionTitle: "New category") { isCreating = true }
            }
        }
    }
}

// MARK: - Editor

private struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: CategoryViewModel
    let category: TaskCategory?

    @State private var name: String
    @State private var colorHex: String
    @State private var symbol: String

    init(viewModel: CategoryViewModel, category: TaskCategory?) {
        self.viewModel = viewModel
        self.category = category
        _name = State(initialValue: category?.wrappedName ?? "")
        _colorHex = State(initialValue: category?.colorHex ?? AccentPalette.blue.color.hexString)
        _symbol = State(initialValue: category?.wrappedSymbol ?? "folder")
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Name", text: $name) }

                Section("Colour") {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.colorChoices, id: \.self) { hex in
                            Circle().fill(Color(hex: hex)).frame(width: 32, height: 32)
                                .overlay {
                                    if colorHex == hex {
                                        Circle().stroke(.primary, lineWidth: 2).padding(-3)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Icon") {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.symbolChoices, id: \.self) { sym in
                            Image(systemName: sym)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(symbol == sym ? .white : .primary)
                                .background(symbol == sym ? Color(hex: colorHex) : Color(.tertiarySystemFill),
                                            in: RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { symbol = sym }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(); dismiss() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func save() {
        if let category {
            viewModel.update(category, name: name, colorHex: colorHex, symbol: symbol)
        } else {
            viewModel.create(name: name, colorHex: colorHex, symbol: symbol)
        }
    }
}
