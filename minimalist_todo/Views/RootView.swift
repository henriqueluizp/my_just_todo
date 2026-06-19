//
//  RootView.swift
//  minimalist_todo
//
//  Top-level tab container. Hosts the planner, insights and settings, applies
//  the live theme + colour scheme from settings, and presents onboarding on
//  first launch. Re-renders the whole tree when the in-app language changes so
//  every string re-localizes; the selected tab survives via @AppStorage.
//

import SwiftUI

struct RootView: View {
    @Environment(\.container) private var container
    @State private var localization = LocalizationManager.shared
    @AppStorage("selectedTab") private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarHomeView(viewModel: container.makeCalendarViewModel())
                .tabItem { Label("Planner", systemImage: "calendar") }
                .tag(0)

            StatisticsView(viewModel: container.makeStatisticsViewModel())
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(container.settings.accent.color)
        .environment(\.theme, container.theme)
        .environment(\.locale, localization.locale)
        .preferredColorScheme(container.settings.appearance.colorScheme)
        .id(localization.refreshID)
        .fullScreenCover(isPresented: showOnboarding) {
            OnboardingView {
                container.settings.hasCompletedOnboarding = true
            }
            .environment(\.theme, container.theme)
            .environment(\.locale, localization.locale)
        }
        .onAppear(perform: applyDebugInitialTab)
    }

    private var showOnboarding: Binding<Bool> {
        Binding(
            get: { !container.settings.hasCompletedOnboarding },
            set: { _ in }
        )
    }

    private func applyDebugInitialTab() {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["INITIAL_TAB"], let tab = Int(raw) {
            selectedTab = tab
        }
        #endif
    }
}
