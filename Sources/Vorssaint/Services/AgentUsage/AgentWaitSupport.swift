// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// One Claude Code process blocked waiting on a person's answer.
struct AgentWaitingSession: Identifiable, Equatable {
    let id: Int32 // pid
    let name: String
}

/// Decides which Claude Code session-status files count as waiting on a
/// reply, kept pure so it is testable without real files or processes.
enum AgentWaitSupport {
    /// One session file's fields, already parsed.
    struct SessionStatus {
        let status: String?
        let pid: Int32?
        let name: String?
        let cwd: String?
    }

    /// The CLI's own name for the session, or the last path component of its
    /// working directory when the name is missing or blank.
    static func sessionName(_ status: SessionStatus) -> String? {
        (status.name.flatMap { $0.isEmpty ? nil : $0 }) ?? status.cwd.map { ($0 as NSString).lastPathComponent }
    }

    /// Which of the given statuses are genuinely waiting on a reply, sorted
    /// by name. `isAlive` stands in for a liveness check like `kill(pid, 0)`
    /// so a session file left behind by a crashed process is never counted.
    static func waitingSessions(_ statuses: [SessionStatus], isAlive: (Int32) -> Bool) -> [AgentWaitingSession] {
        statuses.compactMap { status -> AgentWaitingSession? in
            guard status.status == "waiting", let pid = status.pid, isAlive(pid),
                  let name = sessionName(status) else { return nil }
            return AgentWaitingSession(id: pid, name: name)
        }.sorted { $0.name < $1.name }
    }
}
