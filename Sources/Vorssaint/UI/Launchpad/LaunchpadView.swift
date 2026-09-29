// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct LaunchpadView: View {
    let onDismiss: () -> Void

    @ObservedObject private var catalog = LaunchpadAppCatalog.shared
    @ObservedObject private var l10n = L10n.shared
    @State private var query = ""
    @State private var page = 0
    @State private var layout = LaunchpadLayoutStore.stored()
    @State private var openFolder: LaunchpadFolder?
    @State private var folderPage = 0
    @State private var folderNameDraft = ""
    @FocusState private var searchFocused: Bool

    private var text: LaunchpadStrings { FeatureStrings.launchpad(l10n.language) }

    private var apps: [LaunchpadApp] { catalog.apps }
    private var appsByID: [String: LaunchpadApp] { Dictionary(uniqueKeysWithValues: apps.map { ($0.id, $0) }) }

    /// The grid's tiles in the user's saved order, filtered by the search
    /// query. A folder matches when any app inside it matches.
    private var tiles: [LaunchpadItem] {
        let current = LaunchpadLayoutSupport.applyingCatalog(layout, knownAppIDs: Set(apps.map(\.id)))
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return current.items }
        return current.items.filter { item in
            switch item {
            case .app(let id):
                return appsByID[id].map { !LaunchpadAppSupport.filtered([$0], query: trimmed).isEmpty } ?? false
            case .folder(let folder):
                return folder.appIDs.contains { appsByID[$0].map { !LaunchpadAppSupport.filtered([$0], query: trimmed).isEmpty } ?? false }
            }
        }
    }

    private var pages: [[LaunchpadItem]] {
        guard !tiles.isEmpty else { return [] }
        return stride(from: 0, to: tiles.count, by: LaunchpadAppSupport.perPage)
            .map { Array(tiles[$0..<min($0 + LaunchpadAppSupport.perPage, tiles.count)]) }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.001) // catches clicks on empty background without visibly tinting the desktop
                .onTapGesture(perform: onDismiss)
            VStack(spacing: 24) {
                searchField
                if pages.indices.contains(page) {
                    grid(for: pages[page])
                }
                Spacer()
                if pages.count > 1 { pageDots }
            }
            .padding(.top, 60)
            .padding(.bottom, 90)
            if let openFolder {
                folderOverlay(openFolder)
            }
        }
        .onAppear { refreshOnShow() }
        .onChange(of: query) { page = 0 }
        .onReceive(LaunchpadService.shared.pageStep) { step in
            guard let target = LaunchpadPagingSupport.targetPage(current: page, step: step, pageCount: pages.count) else { return }
            withAnimation(.easeOut(duration: 0.25)) { page = target }
        }
        .onReceive(LaunchpadService.shared.didShow) { refreshOnShow() }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(text.searchPlaceholder, text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
        }
        .padding(.horizontal, 14)
        .frame(width: 280, height: 34)
        .background(HUDBackdrop(cornerRadius: 17, contrast: .high))
        .clipShape(Capsule())
    }

    private func grid(for items: [LaunchpadItem]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 28), count: LaunchpadAppSupport.columns), spacing: 28) {
            ForEach(items) { item in
                tile(for: item)
            }
        }
        .padding(.horizontal, 60)
    }

    @ViewBuilder
    private func tile(for item: LaunchpadItem) -> some View {
        switch item {
        case .app(let id):
            if let app = appsByID[id] {
                appTile(app)
                    .onDrag { NSItemProvider(object: app.id as NSString) }
                    .onDrop(of: [.text], delegate: LaunchpadDropDelegate(targetID: item.id, layout: $layout, newFolderName: text.newFolderDefaultName))
            }
        case .folder(let folder):
            folderTile(folder)
                .onDrop(of: [.text], delegate: LaunchpadDropDelegate(targetID: item.id, layout: $layout, newFolderName: text.newFolderDefaultName))
                .onTapGesture { openFolder = folder }
        }
    }

    private func appTile(_ app: LaunchpadApp) -> some View {
        VStack(spacing: 8) {
            Image(nsImage: LaunchpadIconCache.icon(forPath: app.path))
                .resizable()
                .frame(width: 72, height: 72)
            Text(app.name).font(.system(size: 11)).foregroundStyle(.white).lineLimit(1)
        }
        .frame(width: 96)
        .contentShape(Rectangle())
        .onTapGesture { launch(app) }
    }

    /// The classic Launchpad folder preview: a 3x3 grid of up to nine of the
    /// folder's own icons, shrunk into one tile.
    private func folderTile(_ folder: LaunchpadFolder) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)
                .background(HUDBackdrop(cornerRadius: 16))
                .frame(width: 72, height: 72)
                .overlay {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                        ForEach(folder.appIDs.prefix(9), id: \.self) { id in
                            if let app = appsByID[id] {
                                Image(nsImage: LaunchpadIconCache.icon(forPath: app.path))
                                    .resizable().frame(width: 20, height: 20)
                            }
                        }
                    }
                    .padding(6)
                }
            Text(folder.name).font(.system(size: 11)).foregroundStyle(.white).lineLimit(1)
        }
        .frame(width: 96)
    }

    /// An open folder is a small Launchpad in miniature: its own grid, and
    /// its own pages once it holds more apps than one page can show.
    private func folderOverlay(_ folder: LaunchpadFolder) -> some View {
        let folderApps = folder.appIDs.compactMap { appsByID[$0] }
        let folderPages = LaunchpadAppSupport.folderPages(folderApps)
        return VStack(spacing: 20) {
            TextField(folder.name, text: $folderNameDraft)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 220)
                .onSubmit { commitFolderRename(folder) }
            if folderPages.indices.contains(folderPage) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: LaunchpadAppSupport.folderColumns), spacing: 24) {
                    ForEach(folderPages[folderPage]) { app in
                        appTile(app)
                    }
                }
                .padding(28)
                .background(HUDBackdrop(cornerRadius: 24, contrast: .high))
            }
            if folderPages.count > 1 {
                HStack(spacing: 8) {
                    ForEach(folderPages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == folderPage ? Color.white : Color.white.opacity(0.35))
                            .frame(width: 6, height: 6)
                            .onTapGesture { folderPage = index }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35).onTapGesture {
            commitFolderRename(folder)
            openFolder = nil
        })
        .onChange(of: openFolder) { folderPage = 0; folderNameDraft = openFolder?.name ?? "" }
    }

    /// A blank draft (never typed into, or cleared back to nothing) leaves
    /// the folder's name untouched rather than renaming it to empty.
    private func commitFolderRename(_ folder: LaunchpadFolder) {
        guard !folderNameDraft.trimmingCharacters(in: .whitespaces).isEmpty, folderNameDraft != folder.name else { return }
        let updated = LaunchpadLayoutSupport.renamingFolder(layout, folderID: folder.id, name: folderNameDraft)
        layout = updated
        LaunchpadLayoutStore.save(updated)
        if case .folder(let renamed) = updated.items.first(where: { $0.id == folder.id.uuidString }) {
            openFolder = renamed
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Circle()
                    .fill(index == page ? Color.white : Color.white.opacity(0.35))
                    .frame(width: 7, height: 7)
                    .onTapGesture { page = index }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(HUDBackdrop(cornerRadius: 14))
        .clipShape(Capsule())
        .padding(.bottom, 16)
    }

    /// Re-reads the saved layout and focuses search, both of which only
    /// need to happen once the panel is actually about to be seen.
    private func refreshOnShow() {
        layout = LaunchpadLayoutStore.stored()
        query = ""
        page = 0
        openFolder = nil
        searchFocused = true
    }

    private func launch(_ app: LaunchpadApp) {
        NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        onDismiss()
    }
}

/// Backs both drag-to-reorder and drag-onto-icon-to-create-a-folder: the
/// actual decision (reorder vs. combine vs. add-to-folder) is
/// `LaunchpadLayoutSupport`'s, this delegate only reads the dropped id and
/// writes the result back to the store.
private struct LaunchpadDropDelegate: DropDelegate {
    let targetID: String
    @Binding var layout: LaunchpadLayout
    let newFolderName: String

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { reading, _ in
            guard let draggedID = reading as? String, draggedID != targetID else { return }
            DispatchQueue.main.async {
                let updated: LaunchpadLayout
                if layout.items.contains(where: { $0.id == targetID }) {
                    updated = LaunchpadLayoutSupport.combining(layout, draggedAppID: draggedID, ontoID: targetID,
                                                               defaultFolderName: newFolderName)
                } else {
                    updated = LaunchpadLayoutSupport.moving(layout, itemID: draggedID, beforeItemID: targetID)
                }
                layout = updated
                LaunchpadLayoutStore.save(updated)
            }
        }
        return true
    }
}
