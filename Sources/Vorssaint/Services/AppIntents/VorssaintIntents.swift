// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppIntents
import Foundation

// Actions the Shortcuts app can run. The metadata Shortcuts reads is written
// at build time and cannot follow what is installed, so two things carry that
// rule instead: a picker is built when Shortcuts asks for it and only lists
// what is installed, and every action checks, when it runs, that the person
// allowed Shortcuts to run actions and that its feature is still installed.
//
// Running an action needs the app to be signed with a Team ID; `linkd`
// refuses to connect to an ad hoc or self-signed app.

struct ShortcutsActionError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum ShortcutsActionGate {
    /// Throws the message Shortcuts shows when the action must not run.
    @MainActor
    static func require(_ feature: AppFeature) throws {
        let strings = FeatureStrings.shortcutsActions(L10n.shared.language)
        switch ShortcutsActionsSupport.refusal(
            actionsEnabled: UserDefaults.standard.bool(forKey: DefaultsKey.shortcutsActionsEnabled),
            featureInstalled: feature.isAvailable
        ) {
        case nil: return
        case .disabled: throw ShortcutsActionError(message: strings.disabledMessage)
        case .featureNotInstalled: throw ShortcutsActionError(message: strings.notInstalledMessage)
        }
    }
}

// MARK: - Quick toggles: a picker of what is installed

struct QuickToggleEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Quick toggle")
    static let defaultQuery = QuickToggleEntityQuery()

    var id: String
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct QuickToggleEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [QuickToggleEntity] {
        await installedToggles().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [QuickToggleEntity] {
        await installedToggles()
    }

    /// Empty while the quick toggles feature is uninstalled, so the picker
    /// has nothing to offer for it.
    @MainActor
    private func installedToggles() -> [QuickToggleEntity] {
        guard AppFeature.quickToggles.isAvailable else { return [] }
        let names = FeatureStrings.quickToggles(L10n.shared.language)
        let own = FeatureStrings.shortcutsActions(L10n.shared.language)
        let titles = ["darkMode": own.darkModeName,
                      "lockScreen": names.lockScreenTitle,
                      "displayOff": names.displayOffTitle,
                      "screenSaver": names.screenSaverTitle]
        return ShortcutsActionsSupport.quickToggleIDs.compactMap { id in
            titles[id].map { QuickToggleEntity(id: id, title: $0) }
        }
    }
}

struct RunQuickToggleIntent: AppIntent {
    static let title: LocalizedStringResource = "Run Quick Toggle"
    static let description = IntentDescription("Runs one of the quick toggles from the Vorssaint panel.")

    @Parameter(title: "Quick toggle")
    var toggle: QuickToggleEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Run \(\.$toggle)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try ShortcutsActionGate.require(.quickToggles)
        let service = QuickTogglesService.shared
        switch toggle.id {
        case "darkMode": service.toggleDarkMode()
        case "lockScreen": service.lockScreen()
        case "displayOff": service.turnDisplayOff()
        case "screenSaver": service.startScreenSaver()
        default:
            throw ShortcutsActionError(
                message: FeatureStrings.shortcutsActions(L10n.shared.language).notInstalledMessage)
        }
        return .result()
    }
}

// MARK: - Keep Awake: a typed parameter

enum KeepAwakeDurationOption: String, AppEnum {
    case untilStopped, minutes15, minutes30, hour1, hours2, hours4, hours8

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Duration")
    static let caseDisplayRepresentations: [KeepAwakeDurationOption: DisplayRepresentation] = [
        .untilStopped: "Until stopped",
        .minutes15: "15 minutes",
        .minutes30: "30 minutes",
        .hour1: "1 hour",
        .hours2: "2 hours",
        .hours4: "4 hours",
        .hours8: "8 hours"
    ]

    var minutes: Int {
        switch self {
        case .untilStopped: return 0
        case .minutes15: return 15
        case .minutes30: return 30
        case .hour1: return 60
        case .hours2: return 120
        case .hours4: return 240
        case .hours8: return 480
        }
    }
}

struct KeepAwakeIntent: AppIntent {
    static let title: LocalizedStringResource = "Keep Mac Awake"
    static let description = IntentDescription("Starts a Keep Awake session for the chosen time.")

    @Parameter(title: "Duration", default: .minutes30)
    var duration: KeepAwakeDurationOption

    static var parameterSummary: some ParameterSummary {
        Summary("Keep the Mac awake \(\.$duration)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try ShortcutsActionGate.require(.keepAwake)
        // The same list the panel offers; anything else would turn into "until
        // stopped" inside `activate`, so it is refused here.
        guard let minutes = ShortcutsActionsSupport.keepAwakeMinutes(duration.minutes) else {
            throw ShortcutsActionError(
                message: FeatureStrings.shortcutsActions(L10n.shared.language).notInstalledMessage)
        }
        KeepAwakeManager.shared.activate(minutes: minutes)
        return .result()
    }
}

// MARK: - Keep Awake status: a value that comes back

struct KeepAwakeStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Is Keep Awake On"
    static let description = IntentDescription("Returns whether a Keep Awake session is running.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        try ShortcutsActionGate.require(.keepAwake)
        return .result(value: KeepAwakeManager.shared.isActive)
    }
}

// MARK: - Turning installed features on and off, without a list of their own

struct FeatureToggleEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Vorssaint feature")
    static let defaultQuery = FeatureToggleEntityQuery()

    var id: String
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct FeatureToggleEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FeatureToggleEntity] {
        await switchableFeatures().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [FeatureToggleEntity] {
        await switchableFeatures()
    }

    /// Every installed feature with exactly one plain switch, named the way the
    /// features page names it. The list comes from the catalog, so a feature
    /// added later shows up here with no code of its own.
    @MainActor
    private func switchableFeatures() -> [FeatureToggleEntity] {
        let language = L10n.shared.language
        let strings = L10n.shared.s
        let hub = FeatureStrings.hub(language)
        return AppFeature.allCases.compactMap { feature in
            guard feature.isAvailable,
                  ShortcutsActionsSupport.offersPowerSwitch(enabledKeyCount: feature.enabledKeys.count)
            else { return nil }
            return FeatureToggleEntity(id: feature.rawValue, title: feature.hubTitle(strings, hub: hub))
        }
    }
}

struct SetFeatureEnabledIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn Vorssaint Feature On or Off"
    static let description = IntentDescription(
        "Switches an installed Vorssaint feature on or off, like its switch in Settings.")

    @Parameter(title: "Feature")
    var feature: FeatureToggleEntity

    @Parameter(title: "On", default: true)
    var enabled: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Turn \(\.$feature) \(\.$enabled)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let target = AppFeature(rawValue: feature.id) else {
            throw ShortcutsActionError(
                message: FeatureStrings.shortcutsActions(L10n.shared.language).notInstalledMessage)
        }
        try ShortcutsActionGate.require(target)
        // Checked again here: the list was built earlier, and a feature with
        // several switches must never be guessed at.
        guard ShortcutsActionsSupport.offersPowerSwitch(enabledKeyCount: target.enabledKeys.count),
              let key = target.enabledKeys.first else {
            throw ShortcutsActionError(
                message: FeatureStrings.shortcutsActions(L10n.shared.language).notInstalledMessage)
        }
        UserDefaults.standard.set(enabled, forKey: key)
        FeatureRuntime.shared.sync([target])
        return .result()
    }
}
