//
//  CategoryViewModel.swift
//  minimalist_todo
//
//  Manages the user's categories (create / edit / delete) for the settings
//  category manager.
//

import Observation
import SwiftUI

@MainActor
@Observable
final class CategoryViewModel {
    private(set) var categories: [TaskCategory] = []

    /// Palette offered when creating a category.
    let colorChoices: [String] = AccentPalette.allCases.map { $0.color.hexString }
    let symbolChoices: [String] = [
        "person.fill", "briefcase.fill", "book.fill", "heart.fill",
        "creditcard.fill", "house.fill", "cart.fill", "airplane",
        "dumbbell.fill", "leaf.fill", "star.fill", "gamecontroller.fill"
    ]

    private let repository: CategoryRepositoryProtocol

    init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
        reload()
    }

    func reload() { categories = repository.all() }

    func create(name: String, colorHex: String, symbol: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        repository.create(name: name, colorHex: colorHex, symbol: symbol)
        reload()
    }

    func update(_ category: TaskCategory, name: String, colorHex: String, symbol: String) {
        repository.update(category, name: name, colorHex: colorHex, symbol: symbol)
        reload()
    }

    func delete(_ category: TaskCategory) {
        repository.delete(category)
        reload()
    }

    func delete(at offsets: IndexSet) {
        offsets.map { categories[$0] }.forEach(repository.delete)
        reload()
    }
}
