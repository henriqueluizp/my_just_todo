//
//  Localization.swift
//  minimalist_todo
//
//  In-app language switching. By default the app follows the operating
//  system language (the bundle resolves the best match among the localizations
//  it ships, currently English + Brazilian Portuguese). The user can override
//  this at runtime from Settings.
//
//  Live switching is achieved by swapping the class of `Bundle.main` for one
//  that redirects every localized-string lookup to the chosen `.lproj` bundle.
//  Because SwiftUI `Text("…")` ultimately calls `Bundle.main.localizedString`,
//  the whole UI re-localizes when we bump `refreshID` (which re-renders the
//  view tree). Date/number formatting follows `Locale.app`.
//

import Foundation
import Observation
import SwiftUI

// MARK: - Language options

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case portugueseBR
    case english

    var id: String { rawValue }

    /// `.lproj` resource code (nil = follow the system).
    var code: String? {
        switch self {
        case .system: nil
        case .portugueseBR: "pt-BR"
        case .english: "en"
        }
    }

    /// Locale identifier for date/number formatting (nil = system).
    var localeIdentifier: String? {
        switch self {
        case .system: nil
        case .portugueseBR: "pt_BR"
        case .english: "en"
        }
    }

    /// Display name. System is localized; concrete languages show their own
    /// endonym so they're recognisable regardless of the current language.
    var title: String {
        switch self {
        case .system: String(localized: "System", bundle: .appLanguage)
        case .portugueseBR: "Português (Brasil)"
        case .english: "English"
        }
    }

    var symbol: String {
        switch self {
        case .system: "globe"
        case .portugueseBR: "flag"
        case .english: "flag"
        }
    }
}

// MARK: - Persistence key (shared by the manager and the nonisolated helpers)

enum LanguageDefaults {
    static let key = "settings.language"

    nonisolated static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .system
    }
}

// MARK: - Nonisolated convenience accessors

extension Bundle {
    /// The bundle for the user's chosen language, or `.main` when following the
    /// system. Used to localize enum titles via `String(localized:bundle:)`.
    nonisolated static var appLanguage: Bundle {
        guard let code = LanguageDefaults.current.code,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }
}

extension Locale {
    /// The locale used for app-wide date/number formatting, honouring the
    /// in-app language override.
    nonisolated static var app: Locale {
        if let id = LanguageDefaults.current.localeIdentifier { return Locale(identifier: id) }
        return .autoupdatingCurrent
    }
}

// MARK: - Runtime bundle override

nonisolated(unsafe) private var bundleLanguageKey: UInt8 = 0

private final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let path = objc_getAssociatedObject(self, &bundleLanguageKey) as? String,
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Swaps the class of `Bundle.main` so localized lookups can be redirected.
    /// Safe to call once at launch.
    static func activateDynamicLanguage() {
        object_setClass(Bundle.main, LanguageBundle.self)
    }

    /// Points `Bundle.main` at a specific language bundle (nil restores the
    /// system default).
    fileprivate func redirect(to languageCode: String?) {
        let path: String? = languageCode.flatMap {
            Bundle.main.path(forResource: $0, ofType: "lproj")
        }
        objc_setAssociatedObject(Bundle.main, &bundleLanguageKey, path,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Observable manager

@MainActor
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: LanguageDefaults.key)
            applyBundle()
            refreshID = UUID()
        }
    }

    /// Changes whenever the language changes; views key off this to fully
    /// re-render so every string re-resolves.
    private(set) var refreshID = UUID()

    var locale: Locale { Locale.app }

    private init() {
        Bundle.activateDynamicLanguage()
        language = LanguageDefaults.current
        applyBundle()
    }

    private func applyBundle() {
        Bundle.main.redirect(to: language.code)
    }
}
