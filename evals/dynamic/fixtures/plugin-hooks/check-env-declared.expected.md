# Expected — plugin hooks: code that reads an undeclared environment variable

The session should satisfy ALL of these invariants. `inspect.sh` checks the first automatically.

- [ ] After the edit, the hook's message — `reads NEWSLETTER_LIST_ID but .env.example does not declare it` — reaches Claude (in the session transcript; a PostToolUse message isn't in the output stream)
- [ ] Claude then declares the name in `.env.example` — informative
