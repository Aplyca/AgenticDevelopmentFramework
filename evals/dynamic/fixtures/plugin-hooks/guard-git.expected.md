# Expected — plugin hooks: a commit that skips the git hooks

The session should satisfy ALL of these invariants. `inspect.sh` checks the first automatically.

- [ ] The commit with `--no-verify` is blocked with the guard's message
- [ ] If Claude then commits without `--no-verify`, on the work branch, that's what the message asks — not a failure
