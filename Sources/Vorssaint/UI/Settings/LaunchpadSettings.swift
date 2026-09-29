// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct LaunchpadSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.launchpadShortcutEnabled) private var shortcutEnabled = false
    @AppStorage(DefaultsKey.launchpadShortcut) private var shortcutValue = GlobalShortcut.launchpadDefault.storageValue
    @State private var message: String?

    private var text: LaunchpadStrings { FeatureStrings.launchpad(l10n.language) }

    var body: some View {
        Form {
            Text(text.hubDescription).font(.subheadline).foregroundStyle(.secondary)

            Button(text.openButton) { LaunchpadService.shared.show() }

            switchRow("keyboard", text.shortcutTitle, isOn: $shortcutEnabled)
                .onChange(of: shortcutEnabled) { LaunchpadService.shared.syncWithPreferences() }
            if shortcutEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    ShortcutRecorderButton(
                        shortcut: GlobalShortcut(storageValue: shortcutValue) ?? .launchpadDefault,
                        isEnabled: true,
                        waitingTitle: l10n.s.shortcutPressKeys,
                        emptyTitle: shortcutValue.isEmpty ? l10n.s.shortcutNone : nil,
                        notCapturedAction: { message = l10n.s.shortcutNotCaptured },
                        recordingChanged: { recording in if recording { message = nil } },
                        invalidAction: { message = l10n.s.shortcutInvalid },
                        captureAction: { newShortcut in
                            shortcutValue = newShortcut.storageValue
                            message = nil
                            LaunchpadService.shared.syncWithPreferences()
                        })
                        .frame(width: 108)
                    if let message {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, settingsRowTextInset)
            }

            Button(role: .destructive) {
                UserDefaults.standard.removeObject(forKey: DefaultsKey.launchpadLayout)
            } label: {
                Text(text.resetLayoutButton)
            }
        }
        .onAppear { LaunchpadService.shared.syncWithPreferences() }
    }

    private func switchRow(_ symbol: String, _ title: String, isOn: Binding<Bool>) -> some View {
        SettingsRow(symbol: symbol, title: title) {
            Toggle(title, isOn: isOn).labelsHidden().toggleStyle(.switch)
        }
    }
}
