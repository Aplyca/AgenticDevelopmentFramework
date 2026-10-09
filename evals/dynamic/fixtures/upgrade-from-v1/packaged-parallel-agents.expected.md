# Expected — upgrade from v1: a packaged project with the parallel-agents module moves from v1.4.0 to v2.0.0

The session should satisfy ALL of these invariants. `inspect.sh` checks the end state ones marked
(auto).

## First turn

- [ ] Sees that it runs in a worktree, not the hub, and goes ahead there
- [ ] Reads the stamp (v1.4.0, packaged, `parallel-agents`) and moves to the newest release tag, saying
      the jump crosses a major version
- [ ] Takes the order to upgrade in from the release's changelog section: everything in the packaged
      case, plus the worktree scripts that leave the project and the module's move to `ops/agent/`
- [ ] Presents the plan before changing anything
- [ ] Changes nothing before the answer

## End state (after the follow-up)

- [ ] (auto) `main` is untouched; the upgrade is on the worktree's branch, and everything is committed
- [ ] (auto) Everything the packaged case checks, with `parallel-agents` in the stamp
- [ ] (auto) The module is in `ops/agent/` with its `worktree.conf`, and `scripts/agent/` is gone
- [ ] (auto) No worktree scripts are committed: `adf`'s `adf-worktree-*` commands replace them
- [ ] (auto) Nothing in the project names `scripts/agent/`
- [ ] The pull request body is shown, with each developer's steps after the merge. Nothing is pushed

## Always

- [ ] No outward action (push, pull request) is taken without an ask
- [ ] Nothing is edited in the main checkout
