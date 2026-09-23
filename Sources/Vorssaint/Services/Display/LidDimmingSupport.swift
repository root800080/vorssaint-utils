// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics

/// Captures and restores display brightness for the closed-lid dimming
/// option, over the same DisplayServices route `BrightnessBridge` already
/// resolves for the built-in panel and Apple external displays. Third-party
/// monitors driven only over DDC are out of scope, like the rest of that route.
enum LidDimmingSupport {
    /// The main display plus every other display CoreGraphics reports active.
    /// `CGMainDisplayID()` is included explicitly because the built-in panel
    /// drops out of the active list once the lid physically closes.
    static func knownDisplayIDs() -> [CGDirectDisplayID] {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        CGGetActiveDisplayList(16, &ids, &count)
        var result = Array(ids.prefix(Int(count)))
        let main = CGMainDisplayID()
        if !result.contains(main) { result.insert(main, at: 0) }
        return result
    }

    static func captureBrightnesses() -> [(CGDirectDisplayID, Double)] {
        guard let getBrightness = BrightnessBridge.getBrightness else { return [] }
        return knownDisplayIDs().compactMap { id in
            var value: Float = 0
            guard getBrightness(id, &value) == 0 else { return nil }
            return (id, Double(value))
        }
    }

    static func dimToZero() {
        guard let setBrightness = BrightnessBridge.setBrightness else { return }
        for id in knownDisplayIDs() { _ = setBrightness(id, 0) }
    }

    static func restore(_ saved: [(CGDirectDisplayID, Double)]) {
        guard let setBrightness = BrightnessBridge.setBrightness else { return }
        for (id, value) in saved { _ = setBrightness(id, Float(value)) }
    }
}
