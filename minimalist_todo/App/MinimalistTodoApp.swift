//
//  MinimalistTodoApp.swift
//  minimalist_todo
//
//  Application entry point (SwiftUI lifecycle). Builds the dependency
//  container once and injects it — along with the Core Data context and live
//  theme — into the environment for the whole view tree. Keeps the haptics
//  toggle in sync with the user's setting.
//

import SwiftUI

@main
struct MinimalistTodoApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.container, container)
                .environment(\.managedObjectContext, container.viewContext)
                .environment(\.theme, container.theme)
                .tint(container.settings.accent.color)
                .onChange(of: container.settings.hapticsEnabled) { _, enabled in
                    container.haptics.isEnabled = enabled
                }
        }
    }
}
