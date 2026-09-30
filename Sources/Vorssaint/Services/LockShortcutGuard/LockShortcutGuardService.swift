// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import CoreGraphics
import Combine

/// Asks for a hold or a second press before Control-Command-Q locks the
/// screen. macOS answers that shortcut before a tap sees it, so the system
/// shortcut is switched off through the shared take-over for as long as the
/// guard runs and given back on every exit path. The tap looks at key events
/// only while Control and Command are both held, or while a press it owns is
/// in flight, and passes everything else untouched.
final class LockShortcutGuardService: ObservableObject {
    static let shared = LockShortcutGuardService()

    @Published private(set) var isRunning = false

    private static let takeOverKey = "lockShortcutGuard"
    private static let systemShortcut = GlobalShortcut(keyCode: 12, modifiers: [.control, .command])

    private struct Pending {
        let mode: LockShortcutGuardMode
        let keyCode: Int64
        let timestamp: UInt64
    }

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var holdTimer: Timer?
    private var pendingExpiry: DispatchWorkItem?
    private var swallowExpiry: DispatchWorkItem?
    private var pending: Pending?
    /// Set once a confirmed press locked the screen: the rest of that press
    /// (repeats and the release) is swallowed so it cannot reach an app.
    private var swallowKeyCode: Int64?
    private let hud = QuitProtectionHUD()

    private init() {
        SessionActivity.shared.onChange { [weak self] _ in
            self?.syncWithPreferences()
        }
    }

    // MARK: Preferences

    var isEnabled: Bool {
        AppFeature.quitWindowProtection.isAvailable
            && UserDefaults.standard.bool(forKey: DefaultsKey.lockShortcutGuardEnabled)
    }

    private var mode: LockShortcutGuardMode {
        LockShortcutGuardSupport.modeFor(UserDefaults.standard.string(forKey: DefaultsKey.lockShortcutGuardMode))
    }

    private var holdDurationMilliseconds: Double {
        QuitProtectionSupport.sanitizedHoldDuration(
            UserDefaults.standard.double(forKey: DefaultsKey.lockShortcutGuardHoldDurationMs))
    }

    private var doublePressIntervalMilliseconds: Double {
        QuitProtectionSupport.sanitizedDoublePressInterval(
            UserDefaults.standard.double(forKey: DefaultsKey.lockShortcutGuardDoubleIntervalMs))
    }

    private var showsFeedback: Bool {
        UserDefaults.standard.bool(forKey: DefaultsKey.lockShortcutGuardShowFeedback)
    }

    func syncWithPreferences() {
        guard SessionActivitySupport.tapShouldRun(
            featureWanted: isEnabled,
            accessibilityGranted: AXIsProcessTrusted(),
            sessionIsActive: SessionActivity.shared.isActive
        ) else {
            stop()
            return
        }
        start()
    }

    /// Releases the tap, the system shortcut and any press in flight, for
    /// callers outside this type.
    func suspend() { stop() }

    // MARK: Lifecycle

    private func start() {
        guard !isRunning, installTap() else { return }
        isRunning = true
        // Only once the tap that handles the key exists: the system shortcut
        // is never off without a handler behind it.
        SystemShortcutTakeover.claim(Self.takeOverKey, shortcut: Self.systemShortcut)
        SystemShortcutTakeover.setTakeOver(Self.takeOverKey, true)
    }

    private func stop() {
        cancelPending()
        clearSwallow()
        // Give the shortcut back before the handler goes away.
        SystemShortcutTakeover.setTakeOver(Self.takeOverKey, false)
        SystemShortcutTakeover.release(Self.takeOverKey)
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        isRunning = false
    }

    private func installTap() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.keyUp.rawValue)
            | CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let service = Unmanaged<LockShortcutGuardService>
                    .fromOpaque(userInfo).takeUnretainedValue()
                return service.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    // MARK: Event routing

    private var hasPressInFlight: Bool { pending != nil || swallowKeyCode != nil }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // The release that ends a swallow may be among the events missed.
            cancelPending()
            clearSwallow()
            let shouldRearm = SessionActivitySupport.tapShouldRun(
                featureWanted: isEnabled,
                accessibilityGranted: AXIsProcessTrusted(),
                sessionIsActive: SessionActivity.shared.isActive
            )
            if shouldRearm, let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.stop()
                    self?.syncWithPreferences()
                }
            }
            return Unmanaged.passUnretained(event)
        }
        guard isRunning else { return Unmanaged.passUnretained(event) }

        switch type {
        case .keyDown: return handleKeyDown(event)
        case .keyUp: return handleKeyUp(event)
        case .flagsChanged:
            handleFlagsChanged(event)
            return Unmanaged.passUnretained(event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func handleKeyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let flags = event.flags

        if keyCode == 53, pending != nil {
            cancelPending()
            return nil
        }
        // Ordinary typing stops here: reading which key this is costs an
        // NSEvent and a layout lookup on a tap that sees every keystroke.
        guard (flags.contains(.maskControl) && flags.contains(.maskCommand)) || hasPressInFlight else {
            return Unmanaged.passUnretained(event)
        }
        if let swallowKeyCode, keyCode == swallowKeyCode {
            return nil
        }
        let matches = LockShortcutGuardSupport.isLockShortcut(
            keyCharacter: NSEvent(cgEvent: event)?.charactersIgnoringModifiers?.lowercased(),
            keyCode: keyCode,
            commandLabel: GlobalShortcut.layoutKeyLabel(for: keyCode, usesCommand: true),
            command: flags.contains(.maskCommand),
            control: flags.contains(.maskControl),
            option: flags.contains(.maskAlternate),
            shift: flags.contains(.maskShift))
        guard matches else {
            // Another key ends a confirmation that was waiting for this one.
            if pending != nil { cancelPending() }
            return Unmanaged.passUnretained(event)
        }
        if isRepeat { return nil }

        switch mode {
        case .hold:
            begin(.hold, keyCode: keyCode, event: event)
            return nil
        case .doublePress:
            if let pending, pending.mode == .doublePress,
               QuitProtectionSupport.isWithinDoublePressInterval(
                firstTimestamp: pending.timestamp,
                secondTimestamp: event.timestamp,
                intervalMilliseconds: doublePressIntervalMilliseconds) {
                cancelPending()
                confirm(keyCode: keyCode)
                return nil
            }
            begin(.doublePress, keyCode: keyCode, event: event)
            return nil
        }
    }

    private func handleKeyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        // A release only matters to a press this service is holding. Control
        // and Command cannot be required: the release of Q may well arrive
        // after they were let go.
        guard hasPressInFlight else { return Unmanaged.passUnretained(event) }
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if let swallowKeyCode, keyCode == swallowKeyCode {
            clearSwallow()
            return nil
        }
        guard let pending, keyCode == pending.keyCode else {
            return Unmanaged.passUnretained(event)
        }
        switch pending.mode {
        case .hold:
            cancelPending()
        case .doublePress:
            break
        }
        return nil
    }

    private func handleFlagsChanged(_ event: CGEvent) {
        guard let pending, pending.mode == .hold else { return }
        let flags = event.flags
        if !LockShortcutGuardSupport.holdSurvivesFlagsChange(control: flags.contains(.maskControl),
                                                             command: flags.contains(.maskCommand)) {
            cancelPending()
        }
    }

    // MARK: Confirmation

    private func begin(_ mode: LockShortcutGuardMode, keyCode: Int64, event: CGEvent) {
        cancelPending()
        pending = Pending(mode: mode, keyCode: keyCode, timestamp: event.timestamp)
        let strings = FeatureStrings.quitProtection(L10n.shared.language)
        switch mode {
        case .hold:
            let duration = holdDurationMilliseconds / 1_000
            holdTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.completeHold()
            }
            if showsFeedback {
                hud.show(title: String(format: strings.holdLockHUDFormat, LockShortcutGuardSupport.symbol),
                         detail: strings.cancelHint,
                         holdDeadline: Date().addingTimeInterval(duration))
            }
        case .doublePress:
            let interval = doublePressIntervalMilliseconds
            let expiry = DispatchWorkItem { [weak self] in self?.cancelPending() }
            pendingExpiry = expiry
            DispatchQueue.main.asyncAfter(deadline: .now() + (interval + 100) / 1_000, execute: expiry)
            if showsFeedback {
                hud.show(title: String(format: strings.doubleLockHUDFormat, LockShortcutGuardSupport.symbol),
                         detail: strings.cancelHint)
            }
        }
    }

    private func completeHold() {
        guard let pending, pending.mode == .hold else { return }
        let keyCode = pending.keyCode
        cancelPending()
        confirm(keyCode: keyCode)
    }

    private func confirm(keyCode: Int64) {
        swallowKeyCode = keyCode
        // A release that never reaches this tap, because the screen is already
        // locked, must not leave the key swallowed.
        swallowExpiry?.cancel()
        let expiry = DispatchWorkItem { [weak self] in self?.clearSwallow() }
        swallowExpiry = expiry
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: expiry)
        ScreenLock.lockNow()
    }

    private func cancelPending() {
        holdTimer?.invalidate()
        holdTimer = nil
        pendingExpiry?.cancel()
        pendingExpiry = nil
        pending = nil
        hud.hide()
    }

    private func clearSwallow() {
        swallowExpiry?.cancel()
        swallowExpiry = nil
        swallowKeyCode = nil
    }
}
