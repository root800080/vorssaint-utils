# Launchpad Classic — design

## Why

macOS 27 removed Launchpad. This restores it as an opt-in feature in vorssaint-utils: a full-screen grid of installed apps, opened by the same gesture, Dock icon and (new) a configurable hotkey the original used. A second, reimagined variant was floated in the same conversation and is explicitly **out of scope** here — it gets its own spec once Classic ships and the shared foundation below has proven itself.

## Scope

**In scope:** app discovery, a Classic-style full-screen grid with pages, folders (drag one app onto another), search, drag-to-reorder, deleting a removable app, and three independent triggers (gesture, Dock icon, hotkey).

**Out of scope:** the reimagined/modern variant; anything beyond a best-effort attempt at importing a pre-removal Launchpad layout (see Persistence below — this could not be verified against a real upgraded machine as of this writing).

## Components

### 1. App discovery — `LaunchpadAppCatalog` (impure) + `LaunchpadAppSupport` (pure)

Enumerates installed apps via `NSMetadataQuery` (`kMDItemContentType == 'com.apple.application-bundle'`), public API, live-updating as apps install/uninstall with no FSEvents watcher of our own to maintain. Each result becomes a `LaunchpadApp`: bundle identifier, display name, icon (`NSWorkspace.icon(forFile:)`), path, and a `isDeletable` flag (outside `/System/`).

`LaunchpadAppSupport` holds the pure decisions: matching a search query against a name, and whether a given path counts as deletable. Kept pure and tested through the repo's `Tests/generate_sources.py` pattern, the same way `LidDimmingSupport` and `AgentWaitSupport` are.

### 2. Layout model — `LaunchpadLayoutSupport` (pure) + `LaunchpadLayoutStore` (impure)

The arrangement a person builds — pages, folders, app order — is a hierarchical structure, not a flat ordered list like the Quick Launcher's `PanelOrderItem` cases (which assumes a fixed enum of built-in tools). Modeled as:

```swift
struct LaunchpadLayout: Codable, Equatable {
    struct Page: Codable, Equatable {
        var slots: [Slot]
    }
    enum Slot: Codable, Equatable {
        case app(bundleID: String)
        case folder(name: String, bundleIDs: [String])
    }
    var pages: [Page]
}
```

Persisted as JSON in `UserDefaults` (mirroring how the app already persists other structured, non-enum state), under a new `DefaultsKey.launchpadLayout`. `LaunchpadLayoutSupport` holds the pure operations on this structure — inserting an app, merging two into a folder, removing a deleted app from wherever it sits, reconciling the layout against the catalog's current app set (an app can be uninstalled outside the drawer) — all unit-testable without a real grid or real apps. `LaunchpadLayoutStore` is the thin read/write/persist wrapper `KeepAwakeManager` and friends already use this pattern for.

### 3. Persistence and legacy import

On first open with no saved `LaunchpadLayout`, a best-effort, **unverified** attempt looks for `~/Library/Application Support/Dock/*.db` and tries to read a known Launchpad schema from it. If the file is absent or the schema doesn't match what's expected, this fails silently and the drawer opens with a plain alphabetical grid — never an error, never a blocking prompt. This path could not be tested against a real Mac that used Launchpad on macOS 26 and then moved to 27; the machine available during design had never had Launchpad data to begin with. Confirming or dropping this entirely is follow-up work once real exported data (or a VM upgrade test) is available.

### 4. UI — `LaunchpadView` and friends

A dedicated, borderless, full-screen `NSWindow` (not a panel — nothing here needs panel-specific key-window behavior), `NSVisualEffectView` behind the content for the blur (the same effect several existing views in this app already use). Contents: a search field at the top, a paged grid of app/folder icons below, page dots at the bottom. Drag-and-drop reorders within a page; dropping one icon onto another creates a folder named "New Folder" (editable immediately, no category-detection); dragging to a page's edge pages forward/back. Right-click (or a small overlay button) offers "Show in Finder" and, only when `isDeletable`, "Move to Trash" behind a confirmation. Esc or a click outside closes the drawer without side effects.

### 5. Triggers

Three independent toggles in the new settings page:
- **Hotkey** — reuses `HotkeyManager`, the same registration path the Quick Launcher's shortcut already goes through.
- **Trackpad gesture** — the original four-finger pinch, if it is still free to claim on macOS 27 (needs a hardware check once implementation starts; if the system has reclaimed it, this toggle is disabled with an explanation, the same pattern `NotchEditorStrings.keyboardLightUnavailable` already uses for an unavailable control).
- **Dock icon** — a persistent Dock tile that opens the drawer on click.

### 6. Settings page

A new `SettingsPage.appDrawer` case under the existing **Utilities** category in `SettingsDirectory.swift`, following the exact pattern `.radialMenu` or `.textSnippets` already use: an icon, a title, and search keywords for each of the three triggers and the delete-apps toggle.

## Testing

Pure logic (`LaunchpadAppSupport`, `LaunchpadLayoutSupport`) covered directly, no real filesystem or `NSMetadataQuery` involved, matching every other pure-support type in this codebase. The impure catalog/store/hotkey-registration classes are exercised through the app itself, not unit-tested, the same split the rest of the codebase already draws.

## Open questions carried into implementation

1. Does the four-finger pinch gesture still reach this app on macOS 27, or has the system reclaimed it entirely now that Launchpad is gone?
2. Is the legacy Launchpad `.db` import worth keeping once real exported data is available to test against, or should it be dropped in favor of always starting from a clean alphabetical grid?
