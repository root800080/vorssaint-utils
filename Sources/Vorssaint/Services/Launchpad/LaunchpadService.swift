// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

/// A full-screen, always-key panel — borderless and non-activating like
/// `CommandBarService`'s own panel, but sized to the whole screen instead
/// of a centered content-fit rect. There is no "outside" to click on a
/// full-screen panel, so unlike Command Bar's panel this needs no
/// click-outside monitor: `LaunchpadView`'s own background tap gesture
/// handles dismissal, and only Escape needs a key monitor here.
private final class LaunchpadPanel: OverlayPanel {
    override var canBecomeKey: Bool { true }
}

/// Owns Launchpad Classic's global hotkey and its full-screen panel.
final class LaunchpadService {
    static let shared = LaunchpadService()

    /// A trackpad swipe that crossed the paging threshold; `LaunchpadView`
    /// applies it to its own page index.
    let pageStep = PassthroughSubject<Int, Never>()

    private let hotkey = QuickToolHotkey(id: 61)
    private var panel: NSPanel?
    private var keyMonitor: Any?
    private var scrollMonitor: Any?
    private var swipeCumulativeX: CGFloat = 0

    private init() {
        hotkey.onPress = { [weak self] in self?.toggle() }
    }

    func syncWithPreferences() {
        let available = AppFeature.launchpad.isAvailable
        let enabled = available && UserDefaults.standard.bool(forKey: DefaultsKey.launchpadShortcutEnabled)
        let shortcut = GlobalShortcut.saved(for: DefaultsKey.launchpadShortcut, fallback: .launchpadDefault)
        _ = hotkey.sync(enabled: enabled, shortcut: shortcut, storageKey: DefaultsKey.launchpadShortcut)
        if !available { hide() }
    }

    func suspend() {
        hotkey.unregister()
        hide()
    }

    func toggle() {
        if panel?.isVisible == true { hide() } else { show() }
    }

    func show() {
        LaunchpadAppCatalog.shared.refresh()
        NSApp.activate(ignoringOtherApps: true)
        let panel = ensurePanel()
        panel.orderFrontRegardless()
        panel.makeKey()
        installMonitors()
    }

    func hide() {
        removeMonitors()
        panel?.orderOut(nil)
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }
        let frame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panel = LaunchpadPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                                   backing: .buffered, defer: false)
        panel.title = "Launchpad Classic"
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        // .modalPanel sits above every ordinary window (Settings included)
        // without reaching the Dock's or menu bar's own level, so both stay
        // visible on top of the grid.
        panel.level = .modalPanel
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        // .fullScreenUI is the material AppKit documents for exactly this:
        // a blurred backdrop behind a full-screen app-picking surface. It
        // needs .behindWindow blending, which is why the panel stays
        // non-opaque with a clear background instead of drawing its own fill.
        let blur = NSVisualEffectView(frame: NSRect(origin: .zero, size: frame.size))
        blur.material = .fullScreenUI
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.autoresizingMask = [.width, .height]

        let host = NSHostingView(rootView: LaunchpadView(onDismiss: { [weak self] in self?.hide() }))
        host.frame = NSRect(origin: .zero, size: frame.size)
        host.autoresizingMask = [.width, .height]
        blur.addSubview(host)

        panel.contentView = blur
        self.panel = panel
        return panel
    }

    private func installMonitors() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let panel = self.panel, event.window === panel else { return event }
            guard Int(event.keyCode) == kVK_Escape else { return event }
            self.hide()
            return nil
        }
        swipeCumulativeX = 0
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, let panel = self.panel, event.window === panel else { return event }
            if event.phase.contains(.began) { self.swipeCumulativeX = 0 }
            self.swipeCumulativeX += event.scrollingDeltaX
            if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
                let step = LaunchpadPagingSupport.pageStep(cumulativeX: self.swipeCumulativeX)
                self.swipeCumulativeX = 0
                if step != 0 { self.pageStep.send(step) }
            }
            return event
        }
    }

    private func removeMonitors() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let scrollMonitor { NSEvent.removeMonitor(scrollMonitor) }
        keyMonitor = nil
        scrollMonitor = nil
    }
}
