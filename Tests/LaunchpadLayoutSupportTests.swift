// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum LaunchpadLayoutSupportTests {
    static func run(_ suite: TestSuite) {
        suite.expect(LaunchpadLayoutSupport.applyingCatalog(.initial, knownAppIDs: ["a", "b"]).items.map(\.id) == ["a", "b"],
                     "an empty layout picks up every known app, in catalog order")

        let existing = LaunchpadLayout(items: [.app("b"), .app("a")])
        suite.expect(LaunchpadLayoutSupport.applyingCatalog(existing, knownAppIDs: ["a", "b"]).items.map(\.id) == ["b", "a"],
                     "an existing order is kept as-is when nothing changed")

        suite.expect(LaunchpadLayoutSupport.applyingCatalog(existing, knownAppIDs: ["a"]).items.map(\.id) == ["a"],
                     "an app no longer installed drops out of the layout")

        suite.expect(LaunchpadLayoutSupport.applyingCatalog(existing, knownAppIDs: ["a", "b", "c"]).items.map(\.id) == ["b", "a", "c"],
                     "a newly installed app is appended after the existing order")

        let folder = LaunchpadFolder(id: UUID(), name: "Utilities", appIDs: ["x", "y"])
        let withFolder = LaunchpadLayout(items: [.app("a"), .folder(folder)])
        suite.expect(LaunchpadLayoutSupport.applyingCatalog(withFolder, knownAppIDs: ["a", "x"]).items == [.app("a"), .app("x")],
                     "a folder left with only one app after an uninstall dissolves into that loose app")

        let dissolving = LaunchpadLayout(items: [.app("a"), .folder(LaunchpadFolder(id: folder.id, name: "Utilities", appIDs: ["x"]))])
        suite.expect(LaunchpadLayoutSupport.applyingCatalog(dissolving, knownAppIDs: ["a"]).items == [.app("a")],
                     "a folder left with no apps at all dissolves out of the layout")

        suite.expect(LaunchpadLayoutSupport.moving(LaunchpadLayout(items: [.app("a"), .app("b"), .app("c")]), itemID: "c", beforeItemID: "a").items.map(\.id) == ["c", "a", "b"],
                     "moving an item places it just before its target")

        suite.expect(LaunchpadLayoutSupport.moving(LaunchpadLayout(items: [.app("a"), .app("b")]), itemID: "a", beforeItemID: nil).items.map(\.id) == ["b", "a"],
                     "a nil target moves the item to the very end")

        let combined = LaunchpadLayoutSupport.combining(LaunchpadLayout(items: [.app("a"), .app("b")]), draggedAppID: "a", ontoID: "b", defaultFolderName: "New Folder")
        suite.expect(combined.items.count == 1, "combining two loose apps replaces both with one folder")
        if case .folder(let created) = combined.items.first {
            suite.expect(created.name == "New Folder" && created.appIDs == ["b", "a"],
                         "the new folder is named with the given default and holds the target first, then the dragged app")
        } else {
            suite.expect(false, "combining two apps must produce a folder item")
        }

        let intoFolder = LaunchpadLayoutSupport.combining(LaunchpadLayout(items: [.app("a"), .folder(folder)]), draggedAppID: "a", ontoID: folder.id.uuidString, defaultFolderName: "New Folder")
        suite.expect(intoFolder.items.count == 1, "dragging a loose app onto an existing folder adds it there instead of nesting folders")
        if case .folder(let updated) = intoFolder.items.first {
            suite.expect(updated.appIDs == ["x", "y", "a"], "the app joins at the end of the folder's existing apps")
        } else {
            suite.expect(false, "the target folder must remain a folder item")
        }

        let twoAppFolder = LaunchpadFolder(id: UUID(), name: "Pair", appIDs: ["x", "y"])
        let removed = LaunchpadLayoutSupport.removingFromFolder(LaunchpadLayout(items: [.folder(twoAppFolder)]), appID: "y", folderID: twoAppFolder.id)
        suite.expect(removed.items.map(\.id) == ["x", "y"] && removed.items.allSatisfy { if case .app = $0 { return true }; return false },
                     "removing the second-to-last app dissolves the folder back into two loose apps")

        let threeAppFolder = LaunchpadFolder(id: UUID(), name: "Trio", appIDs: ["x", "y", "z"])
        let removedOne = LaunchpadLayoutSupport.removingFromFolder(LaunchpadLayout(items: [.folder(threeAppFolder)]), appID: "y", folderID: threeAppFolder.id)
        suite.expect(removedOne.items.count == 2, "removing one app from a folder of three keeps the folder with the remaining two")

        let overCapacity = LaunchpadLayout(items: (0..<600).map { .app("\($0)") })
        suite.expect(LaunchpadLayoutSupport.sanitized(overCapacity).items.count == 512,
                     "sanitizing caps the total item count so a corrupted or huge blob can't grow without bound")

        let duplicated = LaunchpadLayout(items: [.app("a"), .app("a"), .app("b")])
        suite.expect(LaunchpadLayoutSupport.sanitized(duplicated).items.map(\.id) == ["a", "b"],
                     "sanitizing drops a duplicate item id")
    }
}
