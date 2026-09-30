// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum LockShortcutGuardMode: String, CaseIterable, Identifiable {
    case hold
    case doublePress

    var id: String { rawValue }
}

/// Pure rules for guarding Control-Command-Q, the shortcut that locks the
/// screen. Timing limits and the layout-aware key match are the ones Quit
/// Protection already uses for Command-Q.
enum LockShortcutGuardSupport {
    static let symbol = "⌃⌘Q"

    static let holdDurationRange = QuitProtectionSupport.holdDurationRange
    static let doublePressIntervalRange = QuitProtectionSupport.doublePressIntervalRange
    static let defaultHoldDurationMilliseconds = QuitProtectionSupport.defaultHoldDurationMilliseconds
    static let defaultDoublePressIntervalMilliseconds = QuitProtectionSupport.defaultDoublePressIntervalMilliseconds

    static func modeFor(_ rawValue: String?) -> LockShortcutGuardMode {
        guard let rawValue, let value = LockShortcutGuardMode(rawValue: rawValue) else { return .hold }
        return value
    }

    /// Exactly Control and Command with the Q key. Any other modifier means a
    /// different shortcut, so a press with Option or Shift is left alone.
    static func isLockShortcut(keyCharacter: String?,
                               keyCode: Int64,
                               commandLabel: String?,
                               command: Bool,
                               control: Bool,
                               option: Bool,
                               shift: Bool) -> Bool {
        guard command, control, !option, !shift else { return false }
        return QuitProtectionSupport.matchesKey(keyCharacter: keyCharacter,
                                                keyCode: keyCode,
                                                commandLabel: commandLabel,
                                                shortcut: .quit)
    }

    /// While a press is held, the confirmation only survives as long as both
    /// modifiers do.
    static func holdSurvivesFlagsChange(control: Bool, command: Bool) -> Bool {
        control && command
    }
}
