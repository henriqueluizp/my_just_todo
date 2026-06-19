//
//  SettingsView.swift
//  minimalist_todo
//
//  Appearance, accent colour, notifications, category management and data
//  management (JSON export / restore). Changes persist immediately through
//  SettingsStore and reschedule notifications as needed.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.container) private var container
    @Environment(\.theme) private var theme

    @State private var localization = LocalizationManager.shared
    @State private var exportURL: URL?
    @State private var isImporting = false
    @State private var alert: AlertState?

    private var settings: SettingsStore { container.settings }

    var body: some View {
        NavigationStack {
            Form {
                languageSection
                appearanceSection
                accentSection
                notificationsSection
                organisationSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(item: $exportURL) { url in
                ShareSheet(items: [url]).presentationDetents([.medium, .large])
            }
            .fileImporter(isPresented: $isImporting,
                          allowedContentTypes: [.json]) { handleImport($0) }
            .alert(item: $alert) { state in
                Alert(title: Text(state.title), message: Text(state.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Sections

    private var languageSection: some View {
        Section("Language") {
            Picker(selection: $localization.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            } label: {
                Label("App language", systemImage: "globe")
            }
            .pickerStyle(.menu)
            .onChange(of: localization.language) { container.haptics.selection() }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker(selection: bindingAppearance) {
                ForEach(AppAppearance.allCases) { mode in
                    Label(mode.title, systemImage: mode.symbol).tag(mode)
                }
            } label: {
                Label("Theme", systemImage: "paintbrush")
            }
            .pickerStyle(.menu)
        }
    }

    private var accentSection: some View {
        Section("Accent colour") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(AccentPalette.allCases) { palette in
                    Circle()
                        .fill(palette.color.gradient)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if settings.accent == palette {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture {
                            container.haptics.selection()
                            withAnimation(.snappy) { settings.accent = palette }
                        }
                        .accessibilityLabel(palette.title)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: bindingNotifications) {
                Label("Enable reminders", systemImage: "bell.badge")
            }
            if settings.notificationsEnabled {
                Toggle(isOn: bindingDailyAgenda) {
                    Label("Daily agenda", systemImage: "sun.horizon")
                }
                if settings.dailyAgendaEnabled {
                    Picker(selection: bindingAgendaHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    } label: {
                        Label("Agenda time", systemImage: "clock")
                    }
                }
            }
        }
    }

    private var organisationSection: some View {
        Section("Organisation") {
            NavigationLink {
                CategoryManagerView(viewModel: container.makeCategoryViewModel())
            } label: {
                Label("Manage categories", systemImage: "folder")
            }
        }
    }

    private var dataSection: some View {
        Section {
            Button { exportBackup() } label: {
                Label("Export backup (JSON)", systemImage: "square.and.arrow.up")
            }
            Button { isImporting = true } label: {
                Label("Restore from backup", systemImage: "square.and.arrow.down")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Backups include every task and category as a portable JSON file. Restore is additive and never overwrites existing items.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Storage", value: "On device (Core Data)")
        }
    }

    // MARK: - Bindings with side effects

    private var bindingAppearance: Binding<AppAppearance> {
        Binding { settings.appearance } set: { settings.appearance = $0 }
    }
    private var bindingAgendaHour: Binding<Int> {
        Binding { settings.dailyAgendaHour } set: {
            settings.dailyAgendaHour = $0; rescheduleAgenda()
        }
    }
    private var bindingNotifications: Binding<Bool> {
        Binding { settings.notificationsEnabled } set: { enabled in
            if enabled {
                Task {
                    let granted = await container.notifications.requestAuthorization()
                    settings.notificationsEnabled = granted
                    if !granted {
                        alert = AlertState(title: "Notifications disabled",
                                           message: "Enable notifications in the system Settings to receive reminders.")
                    }
                }
            } else {
                settings.notificationsEnabled = false
                settings.dailyAgendaEnabled = false
                container.notifications.cancelDailyAgenda()
            }
        }
    }
    private var bindingDailyAgenda: Binding<Bool> {
        Binding { settings.dailyAgendaEnabled } set: {
            settings.dailyAgendaEnabled = $0; rescheduleAgenda()
        }
    }

    // MARK: - Actions

    private func rescheduleAgenda() {
        if settings.dailyAgendaEnabled {
            container.notifications.scheduleDailyAgenda(
                at: DateComponents(hour: settings.dailyAgendaHour, minute: 0))
        } else {
            container.notifications.cancelDailyAgenda()
        }
    }

    private func exportBackup() {
        do {
            exportURL = try ExportService.exportToTemporaryFile(context: container.viewContext)
        } catch {
            alert = AlertState(title: "Export failed", message: error.localizedDescription)
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let needsRelease = url.startAccessingSecurityScopedResource()
            defer { if needsRelease { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                try ExportService.restore(from: data, context: container.viewContext)
                container.haptics.success()
                alert = AlertState(title: "Restore complete",
                                   message: "Your tasks and categories were imported.")
            } catch {
                alert = AlertState(title: "Restore failed", message: error.localizedDescription)
            }
        case .failure(let error):
            alert = AlertState(title: "Restore failed", message: error.localizedDescription)
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        var components = DateComponents(); components.hour = hour; components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return version
    }
}

// MARK: - Helpers

private struct AlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
