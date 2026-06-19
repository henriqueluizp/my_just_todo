//
//  PersistenceController.swift
//  minimalist_todo
//
//  Owns the Core Data stack. Exposes a shared production instance and an
//  in-memory `preview` instance seeded with sample data for SwiftUI previews
//  and unit tests. Automatic merging keeps the UI in sync with background
//  writes, and lightweight migration is enabled for schema evolution.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    /// The Core Data model is loaded exactly once and shared by every
    /// container (production + preview). Loading the same `.xcdatamodel` into
    /// multiple `NSPersistentContainer`s would register the `TaskItem` /
    /// `TaskCategory` classes against two `NSManagedObjectModel`s, making Core
    /// Data unable to disambiguate the entity — which then fails on save.
    static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "minimalist_todo", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load Core Data model 'minimalist_todo'")
        }
        return model
    }()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "minimalist_todo",
                                          managedObjectModel: Self.model)

        if let description = container.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
            // Lightweight migration for future model versions.
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            // Persistent history powers widget/extension sync down the line.
            description.setOption(true as NSNumber,
                                  forKey: NSPersistentHistoryTrackingKey)
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production we'd surface this via the data-management UI
                // and offer a reset; failing fast in development is fine.
                assertionFailure("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.name = "viewContext"
    }

    /// Saves the view context only when there is something to persist.
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            assertionFailure("Save error \(nsError), \(nsError.userInfo)")
        }
    }

    /// Runs a block on a private background context and saves it. Used for
    /// bulk operations (export/import, batch deletes) to keep the UI fluid.
    func performBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            block(context)
            if context.hasChanges {
                try? context.save()
            }
        }
    }

    // MARK: - Previews

    @MainActor
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.viewContext
        SampleData.populate(in: context)
        try? context.save()
        return controller
    }()
}
