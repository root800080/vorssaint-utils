// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum LockShortcutGuardTests {
    static func run(_ suite: TestSuite) {
        typealias Guard = LockShortcutGuardSupport

        func matches(_ character: String? = "q", keyCode: Int64 = 12, label: String? = nil,
                     command: Bool = true, control: Bool = true,
                     option: Bool = false, shift: Bool = false) -> Bool {
            Guard.isLockShortcut(keyCharacter: character, keyCode: keyCode, commandLabel: label,
                                 command: command, control: control, option: option, shift: shift)
        }

        suite.expect(matches(), "Control-Command-Q is the lock shortcut")
        suite.expect(!matches(control: false), "Command-Q alone belongs to Quit Protection")
        suite.expect(!matches(command: false), "Control-Q alone is not the lock shortcut")
        suite.expect(!matches(option: true), "Option changes it into another shortcut")
        suite.expect(!matches(shift: true), "Shift changes it into another shortcut")
        suite.expect(!matches("w", keyCode: 13), "another key with the same modifiers is left alone")
        suite.expect(matches("й", keyCode: 12, label: "q"),
                     "the layout's Command label decides, like Command-Q does on a Russian layout")
        suite.expect(!matches("q", keyCode: 12, label: "w"),
                     "the Command label wins over the bare character")
        suite.expect(matches(nil, keyCode: 12), "the key position is used only while nothing can be read")
        suite.expect(!matches(nil, keyCode: 13), "a different position is not the lock shortcut")

        suite.expect(Guard.holdSurvivesFlagsChange(control: true, command: true),
                     "a hold continues while both modifiers stay down")
        suite.expect(!Guard.holdSurvivesFlagsChange(control: false, command: true),
                     "letting go of Control cancels the hold")
        suite.expect(!Guard.holdSurvivesFlagsChange(control: true, command: false),
                     "letting go of Command cancels the hold")

        suite.expect(Guard.modeFor(nil) == .hold, "the mode defaults to hold")
        suite.expect(Guard.modeFor("doublePress") == .doublePress, "double press is read back")
        suite.expect(Guard.modeFor("extraModifier") == .hold, "a mode this guard lacks falls back to hold")
        suite.expect(Guard.holdDurationRange == QuitProtectionSupport.holdDurationRange,
                     "the hold limits are the ones Quit Protection uses")
    }
}
