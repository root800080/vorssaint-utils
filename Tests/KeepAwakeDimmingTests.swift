// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Exercises the closed-lid screen-dimming decisions and their IOKit-backed
/// observer through the same production bodies and fake IOKit as the rest of
/// the closed-lid suite. `C.reset()` leaves the fixture lid closed, so every
/// scenario here opens it before arming, closing again is what triggers dimming.
enum KeepAwakeDimmingTests {
    private typealias C = KeepAwakeLidSleepContract

    /// A session with the option armed and the lid open, ready to be closed.
    private static func armed(reading: Double? = 0.6) -> C.Service {
        let service = C.reset()
        C.BrightnessService.lid = false
        service.isActive = true
        service.clamshellActive = true
        C.LidDisplayDimmer.reading = reading
        service.dimScreenOnLidClose = true
        return service
    }

    /// Same, for the keyboard-backlight option.
    private static func armedKeyboard(reading: Double? = 0.6) -> C.Service {
        let service = C.reset()
        C.BrightnessService.lid = false
        service.isActive = true
        service.clamshellActive = true
        C.LidKeyboardDimmer.reading = reading
        service.dimKeyboardOnLidClose = true
        return service
    }

    static func run(expect: (Bool, String) -> Void) {
        let closing = armed()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidDisplayDimmer.written == [0] && closing.savedDisplayBrightness == 0.6
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedDisplaySavedBrightness] == 0.6,
               "closing the lid saves the current brightness and dims the panel to zero")

        for reading in [0.0, nil] as [Double?] {
            let unreadable = armed(reading: reading)
            C.BrightnessService.lid = true
            C.DimmingObserver.callback?()
            C.drain()
            expect(C.LidDisplayDimmer.written.isEmpty && unreadable.savedDisplayBrightness == nil
                   && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedDisplaySavedBrightness] == nil,
                   "a panel that already reads asleep is left alone instead of being saved as zero")
        }

        let opening = armed()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        C.BrightnessService.lid = false
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidDisplayDimmer.written == [0, 0.6] && opening.savedDisplayBrightness == nil
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedDisplaySavedBrightness] == nil,
               "opening the lid restores the saved brightness and clears the recovery marker")

        let toggledOff = armed()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        toggledOff.dimScreenOnLidClose = false
        expect(C.LidDisplayDimmer.written == [0, 0.6] && toggledOff.savedDisplayBrightness == nil,
               "switching the option off while dimmed restores at once, without waiting for the lid to open")

        let sessionEnded = armed()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        sessionEnded.clamshellActive = false
        expect(C.LidDisplayDimmer.written == [0, 0.6] && sessionEnded.savedDisplayBrightness == nil,
               "the closed-lid session ending while dimmed restores without waiting for the lid to open")

        let tornDown = armed()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        let stale = C.DimmingObserver.callback
        tornDown.dimScreenOnLidClose = false
        C.LidDisplayDimmer.written = []
        stale?()
        C.drain()
        expect(C.LidDisplayDimmer.written.isEmpty,
               "a lid notification that lands after the mode already ended changes nothing")

        let recovering = C.reset()
        C.UserDefaults.standard.set(0.4, forKey: C.DefaultsKey.dimmedDisplaySavedBrightness)
        recovering.recoverDimmedDisplayIfNeeded()
        expect(C.LidDisplayDimmer.written == [0.4]
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedDisplaySavedBrightness] == nil,
               "a brightness saved before a crash is restored and cleared on the next launch")

        let nothingToRecover = C.reset()
        nothingToRecover.recoverDimmedDisplayIfNeeded()
        expect(C.LidDisplayDimmer.written.isEmpty, "launch recovery does nothing when no brightness was saved")

        // A restore that briefly finds no panel — right as the lid opens —
        // keeps the saved level instead of clearing it on a merely attempted
        // write, and a queued retry completes it once the panel is back.
        let retrying = armed()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        C.LidDisplayDimmer.writeSucceeds = false
        C.BrightnessService.lid = false
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidDisplayDimmer.written == [0] && retrying.savedDisplayBrightness == 0.6
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedDisplaySavedBrightness] == 0.6,
               "a restore that finds no panel yet keeps the saved level and its marker instead of clearing them")
        C.LidDisplayDimmer.writeSucceeds = true
        C.DispatchQueue.main.advance()
        expect(C.LidDisplayDimmer.written == [0, 0.6] && retrying.savedDisplayBrightness == nil,
               "the queued retry restores it once the panel answers, with no further lid event needed")

        // Exhausting every retry while the option is switched off keeps the
        // lid observer armed instead of tearing it down, so a later real
        // lid-open event still gets a chance to finish the restore.
        let exhausted = armed()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        C.LidDisplayDimmer.writeSucceeds = false
        exhausted.dimScreenOnLidClose = false
        for _ in 0..<8 { C.DispatchQueue.main.advance() }
        expect(C.LidDisplayDimmer.written == [0] && exhausted.savedDisplayBrightness == 0.6
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedDisplaySavedBrightness] == 0.6
               && C.DimmingObserver.destroyedPorts == 0,
               "exhausting the retries after the option is switched off still owes the restore and keeps watching the lid")
        C.LidDisplayDimmer.writeSucceeds = true
        C.BrightnessService.lid = false
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidDisplayDimmer.written == [0, 0.6] && exhausted.savedDisplayBrightness == nil
               && C.DimmingObserver.destroyedPorts == 1,
               "the lid actually opening finishes the owed restore and only then releases the observer")

        // Same scenarios again for the keyboard backlight, which writes
        // through a separate dim (immediate) and restore path rather than
        // one shared write function.
        let closingKeyboard = armedKeyboard()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidKeyboardDimmer.dimmed == [0] && closingKeyboard.savedKeyboardBrightness == 0.6
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedKeyboardSavedBrightness] == 0.6,
               "closing the lid saves the current keyboard level and dims it to zero")

        for reading in [0.0, nil] as [Double?] {
            let unreadableKeyboard = armedKeyboard(reading: reading)
            C.BrightnessService.lid = true
            C.DimmingObserver.callback?()
            C.drain()
            expect(C.LidKeyboardDimmer.dimmed.isEmpty && unreadableKeyboard.savedKeyboardBrightness == nil
                   && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedKeyboardSavedBrightness] == nil,
                   "a keyboard reading that already reads off is left alone instead of being saved as zero")
        }

        let openingKeyboard = armedKeyboard()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        C.BrightnessService.lid = false
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidKeyboardDimmer.dimmed == [0] && C.LidKeyboardDimmer.restored == [0.6]
               && openingKeyboard.savedKeyboardBrightness == nil
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedKeyboardSavedBrightness] == nil,
               "opening the lid restores the saved keyboard level and clears the recovery marker")

        let toggledOffKeyboard = armedKeyboard()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        toggledOffKeyboard.dimKeyboardOnLidClose = false
        expect(C.LidKeyboardDimmer.restored == [0.6] && toggledOffKeyboard.savedKeyboardBrightness == nil,
               "switching the keyboard option off while dimmed restores at once")

        let sessionEndedKeyboard = armedKeyboard()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        sessionEndedKeyboard.clamshellActive = false
        expect(C.LidKeyboardDimmer.restored == [0.6] && sessionEndedKeyboard.savedKeyboardBrightness == nil,
               "the closed-lid session ending while the keyboard is dimmed restores it")

        let tornDownKeyboard = armedKeyboard()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        let staleKeyboard = C.DimmingObserver.callback
        tornDownKeyboard.dimKeyboardOnLidClose = false
        C.LidKeyboardDimmer.dimmed = []; C.LidKeyboardDimmer.restored = []
        staleKeyboard?()
        C.drain()
        expect(C.LidKeyboardDimmer.dimmed.isEmpty && C.LidKeyboardDimmer.restored.isEmpty,
               "a lid notification landing after the keyboard option already ended changes nothing")

        let recoveringKeyboard = C.reset()
        C.UserDefaults.standard.set(0.3, forKey: C.DefaultsKey.dimmedKeyboardSavedBrightness)
        recoveringKeyboard.recoverDimmedKeyboardIfNeeded()
        expect(C.LidKeyboardDimmer.restored == [0.3]
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedKeyboardSavedBrightness] == nil,
               "a keyboard level saved before a crash is restored and cleared on the next launch")

        let nothingToRecoverKeyboard = C.reset()
        nothingToRecoverKeyboard.recoverDimmedKeyboardIfNeeded()
        expect(C.LidKeyboardDimmer.restored.isEmpty,
               "keyboard launch recovery does nothing when no level was saved")

        // Same owed-until-success retry behavior as the screen, for the
        // keyboard's own restore.
        let retryingKeyboard = armedKeyboard()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        C.LidKeyboardDimmer.writeSucceeds = false
        C.BrightnessService.lid = false
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidKeyboardDimmer.restored.isEmpty && retryingKeyboard.savedKeyboardBrightness == 0.6
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedKeyboardSavedBrightness] == 0.6,
               "a keyboard restore that finds no bridge yet keeps the saved level and its marker")
        C.LidKeyboardDimmer.writeSucceeds = true
        C.DispatchQueue.main.advance()
        expect(C.LidKeyboardDimmer.restored == [0.6] && retryingKeyboard.savedKeyboardBrightness == nil,
               "the queued retry restores the keyboard once the bridge answers")

        let exhaustedKeyboard = armedKeyboard()
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        C.LidKeyboardDimmer.writeSucceeds = false
        exhaustedKeyboard.dimKeyboardOnLidClose = false
        for _ in 0..<8 { C.DispatchQueue.main.advance() }
        expect(C.LidKeyboardDimmer.restored.isEmpty && exhaustedKeyboard.savedKeyboardBrightness == 0.6
               && C.UserDefaults.standard.doubles[C.DefaultsKey.dimmedKeyboardSavedBrightness] == 0.6
               && C.DimmingObserver.destroyedPorts == 0,
               "exhausting the keyboard retries after the option is off still owes the restore and keeps watching the lid")
        C.LidKeyboardDimmer.writeSucceeds = true
        C.BrightnessService.lid = false
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidKeyboardDimmer.restored == [0.6] && exhaustedKeyboard.savedKeyboardBrightness == nil
               && C.DimmingObserver.destroyedPorts == 1,
               "the lid actually opening finishes the owed keyboard restore and only then releases the observer")

        // Both options armed together only touch what each one owns.
        let both = C.reset()
        C.BrightnessService.lid = false
        both.isActive = true
        both.clamshellActive = true
        C.LidDisplayDimmer.reading = 0.6
        C.LidKeyboardDimmer.reading = 0.5
        both.dimScreenOnLidClose = true
        both.dimKeyboardOnLidClose = true
        C.BrightnessService.lid = true
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidDisplayDimmer.written == [0] && C.LidKeyboardDimmer.dimmed == [0]
               && both.savedDisplayBrightness == 0.6 && both.savedKeyboardBrightness == 0.5,
               "one lid-close event dims both the panel and the keyboard when both options are on")
        C.BrightnessService.lid = false
        C.DimmingObserver.callback?()
        C.drain()
        expect(C.LidDisplayDimmer.written == [0, 0.6] && C.LidKeyboardDimmer.restored == [0.5]
               && both.savedDisplayBrightness == nil && both.savedKeyboardBrightness == nil,
               "one lid-open event restores both")
    }
}
