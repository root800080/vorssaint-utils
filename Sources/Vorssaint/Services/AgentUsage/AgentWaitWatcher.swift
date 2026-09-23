// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Darwin
import Foundation

/// Watches Claude Code's own per-process session files
/// (`~/.claude/sessions/<pid>.json`) for a session the CLI itself marked
/// `"waiting"` — genuinely blocked on a reply, not merely a turn that ended
/// with nothing further to ask (that state reads `"idle"` in the same file).
/// Claude only: Codex keeps no equivalent lightweight per-session status file
/// to watch the same way. Which sessions count is decided by `AgentWaitSupport`,
/// kept pure and testable without real files or processes.
final class AgentWaitWatcher: ObservableObject {
    static let shared = AgentWaitWatcher()

    @Published private(set) var waiting: [AgentWaitingSession] = []

    private static let root = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: ".claude/sessions", directoryHint: .isDirectory)
    private let queue = DispatchQueue(label: "com.vorssaint.utils.agentwait", qos: .utility)
    private var watcher: AgentLogWatcher?
    private var running = false

    private init() {}

    func syncWithPreferences() {
        let wanted = NotchAgentSupport.isEnabled()
            && NotchAgentSupport.providers().contains(.claude)
            && UserDefaults.standard.bool(forKey: DefaultsKey.notchAgentsWaitingAlert)
        if wanted { start() } else { stop() }
    }

    private func start() {
        guard !running else { return }
        running = true
        queue.async { [weak self] in self?.rescan() }
        let watcher = self.watcher ?? AgentLogWatcher(queue: queue) { [weak self] _, _ in self?.rescan() }
        self.watcher = watcher
        _ = watcher.start([Self.root.path])
    }

    func stop() {
        guard running else { return }
        running = false
        watcher?.stop()
        if !waiting.isEmpty { waiting = [] }
    }

    /// Runs on `queue`. Reads every session file fresh each time: the
    /// directory holds one small file per Claude process, never enough of
    /// them to make a cursor worth keeping.
    private func rescan() {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: Self.root.path)) ?? []
        let statuses = names.filter { $0.hasSuffix(".json") }.compactMap { name -> AgentWaitSupport.SessionStatus? in
            let path = Self.root.appendingPathComponent(name).path
            guard let data = FileManager.default.contents(atPath: path),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            return AgentWaitSupport.SessionStatus(
                status: json["status"] as? String,
                pid: (json["pid"] as? NSNumber)?.int32Value,
                name: json["name"] as? String,
                cwd: json["cwd"] as? String)
        }
        // A session file outlives a crashed process; only a live one is
        // actually waiting on anybody.
        let sorted = AgentWaitSupport.waitingSessions(statuses) { kill($0, 0) == 0 }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.waiting != sorted else { return }
            self.waiting = sorted
        }
    }
}
