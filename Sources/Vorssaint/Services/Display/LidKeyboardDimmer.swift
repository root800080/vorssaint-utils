// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Reads and writes the keyboard backlight for closed-lid dimming, over the
/// same `KeyboardLightBridge` (CoreBrightness) the app's own keyboard-light
/// toggle and hotkeys already use, rather than a second, separate path.
enum LidKeyboardDimmer {
    /// Reads with idle dimming suspended, so a light the system's own
    /// inactivity timer already turned off does not read the same as one
    /// this app dimmed itself or one the person turned off — either of which
    /// means there is nothing here for a lid close to dim.
    static func currentBrightness() -> Double? {
        guard let level = BrightnessService.sharedKeyboardLightBridge?.brightnessIgnoringIdleDimming(),
              level.isFinite
        else { return nil }
        return Double(level)
    }

    /// Never commits: a lid cycle should not move the keyboard's own saved
    /// brightness or its automatic-light curve, the way the quick toggle and
    /// hotkeys are meant to.
    static func dimToZero() {
        _ = BrightnessService.sharedKeyboardLightBridge?.setBrightness(0, commit: false)
    }

    @discardableResult
    static func restore(_ value: Double) -> Bool {
        BrightnessService.sharedKeyboardLightBridge?.setBrightness(Float(value), commit: false) ?? false
    }
}
