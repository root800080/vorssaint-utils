// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum ShortcutsActionsTests {
    static func run(_ suite: TestSuite) {
        typealias Support = ShortcutsActionsSupport

        suite.expect(Support.refusal(actionsEnabled: false, featureInstalled: true) == .disabled,
                     "an action stays refused until the person allows Shortcuts to run them")
        suite.expect(Support.refusal(actionsEnabled: false, featureInstalled: false) == .disabled,
                     "the switch is the first thing an action reports, installed or not")
        suite.expect(Support.refusal(actionsEnabled: true, featureInstalled: false) == .featureNotInstalled,
                     "an allowed action still refuses for a feature that is uninstalled")
        suite.expect(Support.refusal(actionsEnabled: true, featureInstalled: true) == nil,
                     "an allowed action of an installed feature runs")

        suite.expect(Support.offersPowerSwitch(enabledKeyCount: 1),
                     "a feature with one switch can be turned on and off")
        suite.expect(!Support.offersPowerSwitch(enabledKeyCount: 0),
                     "a feature that works on demand has nothing to turn on")
        suite.expect(!Support.offersPowerSwitch(enabledKeyCount: 2),
                     "a feature with two switches leaves 'on' ambiguous")

        suite.expect(!Support.quickToggleIDs.isEmpty, "Shortcuts is offered some quick toggles")
        suite.expect(!Support.quickToggleIDs.contains("emptyTrash"),
                     "emptying the Trash is never offered without a confirmation")
        suite.expect(!Support.quickToggleIDs.contains("ejectDisks"),
                     "ejecting disks is never offered to an automation")
        suite.expect(Set(Support.quickToggleIDs).count == Support.quickToggleIDs.count,
                     "each quick toggle is offered once")

        for minutes in Defaults.allowedDurations {
            suite.expect(Support.keepAwakeMinutes(minutes) == minutes,
                         "the panel's own duration of \(minutes) minutes is accepted as it is")
        }
        suite.expect(Support.keepAwakeMinutes(0) == 0, "zero stays until stopped")
        suite.expect(Support.keepAwakeMinutes(7) == nil,
                     "a duration the panel does not offer is refused, not turned into until stopped")
        suite.expect(Support.keepAwakeMinutes(-5) == nil, "a negative duration is refused")
        suite.expect(Support.keepAwakeMinutes(100_000) == nil, "an enormous duration is refused")
    }
}
