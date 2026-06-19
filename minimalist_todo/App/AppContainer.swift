//
//  AppContainer.swift
//  minimalist_todo
//
//  Composition root. Constructs the persistence stack, repositories and
//  services once and exposes them to the view tree through the environment.
//  View models receive their dependencies from here, keeping construction in
//  a single place (Dependency Injection) rather than scattered singletons.
//

import CoreData
import Observation
import SwiftUI

@MainActor
@Observable
final class AppContainer {
    let persistence: PersistenceController
    let settings: SettingsStore
    let haptics: HapticsManager
    let notifications: NotificationManager

    let taskRepository: TaskRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol

    var viewContext: NSManagedObjectContext { persistence.viewContext }

    /// Live theme derived from the current accent selection.
    var theme: Theme { Theme(accent: settings.accent.color) }

    init(persistence: PersistenceController = .shared,
         settings: SettingsStore? = nil) {
        self.persistence = persistence
        let settings = settings ?? SettingsStore()
        self.settings = settings

        let haptics = HapticsManager()
        haptics.isEnabled = settings.hapticsEnabled
        self.haptics = haptics
        self.notifications = NotificationManager()

        self.taskRepository = CoreDataTaskRepository(context: persistence.viewContext)
        self.categoryRepository = CoreDataCategoryRepository(context: persistence.viewContext)

        // Ensure the default category set exists on first launch.
        SampleData.seedDefaultCategoriesIfNeeded(in: persistence.viewContext)

        #if DEBUG
        // Demo/UI-test aid: launch with SEED_SAMPLE_DATA=1 to populate sample
        // tasks into an empty store. Never runs in release builds.
        if ProcessInfo.processInfo.environment["SEED_SAMPLE_DATA"] == "1" {
            let request = TaskItem.fetchAllActive()
            if (try? persistence.viewContext.count(for: request)) == 0 {
                SampleData.populate(in: persistence.viewContext)
                try? persistence.viewContext.save()
            }
        }
        #endif
    }

    // MARK: - Factories

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(repository: taskRepository, settings: settings, haptics: haptics)
    }

    func makeStatisticsViewModel() -> StatisticsViewModel {
        StatisticsViewModel(context: viewContext)
    }

    func makeCategoryViewModel() -> CategoryViewModel {
        CategoryViewModel(repository: categoryRepository)
    }

    func makeEditViewModel(editing task: TaskItem?, defaultDate: Date) -> TaskEditViewModel {
        TaskEditViewModel(task: task, defaultDate: defaultDate,
                          taskRepository: taskRepository,
                          categoryRepository: categoryRepository,
                          notifications: notifications,
                          settings: settings, haptics: haptics)
    }

    // MARK: - Preview helper

    @MainActor
    static var preview: AppContainer {
        AppContainer(persistence: .preview, settings: SettingsStore(defaults: previewDefaults))
    }

    private static let previewDefaults: UserDefaults = {
        let defaults = UserDefaults(suiteName: "preview")!
        defaults.removePersistentDomain(forName: "preview")
        return defaults
    }()
}

// MARK: - Environment access

private struct AppContainerKey: EnvironmentKey {
    @MainActor static let defaultValue = AppContainer.preview
}

extension EnvironmentValues {
    var container: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
