# Expected — plugin docs: the session finds a reference doc in the plugin

The session should satisfy ALL of these invariants. `inspect.sh` checks them automatically.

- [ ] The session context names the plugin's `docs/` folder
- [ ] Claude reads `MEMORY-STRATEGY.md` from that folder and answers with its first heading, `# Memory strategy`
- [ ] No read of the plugin's folder asks for permission
- [ ] Claude doesn't fetch the GitHub link
