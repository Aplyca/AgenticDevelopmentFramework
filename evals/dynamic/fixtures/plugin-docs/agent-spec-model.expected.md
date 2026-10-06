# Expected — plugin docs: an agent reads the spec model from the plugin

The session should satisfy ALL of these invariants. `inspect.sh` checks the first two automatically.

- [ ] The agent reads `SPEC-MODEL.md` from the plugin's `docs/` folder, by its full path
- [ ] No read of the plugin's folder asks for permission (none is denied in the headless run)
- [ ] The agent doesn't look for `docs/SPEC-MODEL.md` in the project, or on GitHub
