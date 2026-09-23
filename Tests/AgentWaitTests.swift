// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum AgentWaitTests {
    private typealias Status = AgentWaitSupport.SessionStatus

    static func run(_ suite: TestSuite) {
        let alive: (Int32) -> Bool = { $0 == 1 }

        let waiting = Status(status: "waiting", pid: 1, name: "vorssaint-utils-bf", cwd: "/tmp/vorssaint-utils")
        let busy = Status(status: "busy", pid: 2, name: "other", cwd: "/tmp/other")
        let idle = Status(status: "idle", pid: 3, name: "third", cwd: "/tmp/third")
        let dead = Status(status: "waiting", pid: 4, name: "dead", cwd: "/tmp/dead")
        let unnamed = Status(status: "waiting", pid: 1, name: nil, cwd: "/Users/me/Documents/some-project")
        let blank = Status(status: "waiting", pid: 1, name: "", cwd: nil)

        suite.expect(AgentWaitSupport.waitingSessions([waiting, busy, idle], isAlive: alive)
                     == [AgentWaitingSession(id: 1, name: "vorssaint-utils-bf")],
                     "only a session the CLI marked waiting is reported")

        suite.expect(AgentWaitSupport.waitingSessions([dead], isAlive: alive).isEmpty,
                     "a waiting status left behind by a crashed process is not reported")

        suite.expect(AgentWaitSupport.waitingSessions([unnamed], isAlive: alive)
                     == [AgentWaitingSession(id: 1, name: "some-project")],
                     "a session with no name falls back to its working directory's last component")

        suite.expect(AgentWaitSupport.waitingSessions([blank], isAlive: alive).isEmpty,
                     "a blank name with no working directory to fall back to is skipped rather than shown empty")

        let second = Status(status: "waiting", pid: 1, name: "second", cwd: nil)
        let first = Status(status: "waiting", pid: 1, name: "first", cwd: nil)
        suite.expect(AgentWaitSupport.waitingSessions([second, first], isAlive: alive).map(\.name) == ["first", "second"],
                     "multiple waiting sessions are sorted by name")

        suite.expect(AgentWaitSupport.sessionName(Status(status: nil, pid: nil, name: "", cwd: "/a/b/c")) == "c",
                     "an empty name is treated the same as a missing one")
    }
}
