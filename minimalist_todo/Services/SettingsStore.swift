//
//  SettingsStore.swift
//  minimalist_todo
//
//  Observable wrapper around UserDefaults for all lightweight preferences.
//  Using @Observable keeps SwiftUI views in sync automatically while the
//  property observers persist each change immediately (automatic saving).
//

import Observation
import SwiftUI

@MainActor
@Observable
final class SettingsStore {
    private enum Key {
        static let appearance = "settings.appearance"
        static let accent = "settings.accent"
        static let haptics = "settings.haptics"
        static let notifications = "settings.notifications"
        static let dailyAgenda = "settings.dailyAgenda"
        static let dailyAgendaHour = "settings.dailyAgendaHour"
        static let sortOption = "settings.sortOption"
        static let onboardingDone = "settings.onboardingDone"
    }

    private let defaults: UserDefaults

    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }
    var accent: AccentPalette {
        didSet { defaults.set(accent.rawValue, forKey: Key.accent) }
    }
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.haptics) }
    }
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notifications) }
    }
    var dailyAgendaEnabled: Bool {
        didSet { defaults.set(dailyAgendaEnabled, forKey: Key.dailyAgenda) }
    }
    /// Hour of day (0–23) for the daily agenda notification.
    var dailyAgendaHour: Int {
        didSet { defaults.set(dailyAgendaHour, forKey: Key.dailyAgendaHour) }
    }
    var sortOption: TaskSortOption {
        didSet { defaults.set(sortOption.rawValue, forKey: Key.sortOption) }
    }
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.onboardingDone) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.appearance = AppAppearance(rawValue: defaults.string(forKey: Key.appearance) ?? "")
            ?? .system
        self.accent = AccentPalette(rawValue: defaults.string(forKey: Key.accent) ?? "")
            ?? .blue
        self.hapticsEnabled = defaults.object(forKey: Key.haptics) as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: Key.notifications) as? Bool ?? false
        self.dailyAgendaEnabled = defaults.object(forKey: Key.dailyAgenda) as? Bool ?? false
        self.dailyAgendaHour = defaults.object(forKey: Key.dailyAgendaHour) as? Int ?? 8
        self.sortOption = TaskSortOption(rawValue: defaults.string(forKey: Key.sortOption) ?? "")
            ?? .dueDate
        self.hasCompletedOnboarding = defaults.bool(forKey: Key.onboardingDone)
    }
}
