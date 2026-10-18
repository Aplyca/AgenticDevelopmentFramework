# Shared services

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: what this project's worktrees share, and what a task may copy -->

Every task runs in a worktree of its own (`docs/PARALLEL-AGENTS.md`), and each worktree shares
whatever its env file points at — a local service, a test account, a sandbox. This page records
which services this project's worktrees share, which ones a task may start its own copy of, and what
a copy costs. How a task runs a copy of its own: `docs/PARALLEL-AGENTS.md` § Shared services.

<!-- CUSTOMIZE: what worktrees share, what a task may copy, and what that costs -->
