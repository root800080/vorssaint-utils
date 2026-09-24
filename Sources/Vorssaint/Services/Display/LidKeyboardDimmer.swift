// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Reads and writes the keyboard backlight for closed-lid dimming, over the
/// same `KeyboardLightBridge` (CoreBrightness) the app's own keyboard-light
/// toggle and hotkeys already use, rather than a second, separate path.
enum LidKeyboardDimmer {
    static func currentBrightness() -> Double? {
        guard let level = BrightnessService.sharedKeyboardLightBridge?.brightness(), level.isFinite
        else { return nil }
        return Double(level)
    }

    static func dimToZero() {
        _ = BrightnessService.sharedKeyboardLightBridge?.setBrightness(0)
    }

    /// Holds the shared bridge's idle-dimming suspension well past the write,
    /// since a restore fired by the lid opening has no real key press behind
    /// it to keep an already-expired idle timer from dimming it right back
    /// down.
    @discardableResult
    static func restore(_ value: Double) -> Bool {
        BrightnessService.sharedKeyboardLightBridge?.setBrightnessHoldingIdleSuspension(Float(value)) ?? false
    }
}
