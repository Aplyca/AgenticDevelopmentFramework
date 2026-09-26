# Contributing to the AI-Assisted Development Framework

Thanks for helping improve the framework. This repository is not an application — it is a portable skeleton, documentation, and the `aplyca-framework` Claude Code plugin. Its "code" is mostly prompts, rules, and templates that end up inside other teams' repositories, so a one-line change here changes how many AI agents behave. The guidelines below exist to keep those changes safe to adopt.

## Ways to contribute

- **Report a problem** — open an issue describing what you expected, what the AI or the template did instead, and which tool you used (Claude Code, Cursor, Copilot, Antigravity, …).
- **Improve the skeleton** — clearer rules, better skill instructions, missing spec sections, tool-compatibility fixes.
- **Add worked material** — new playbooks in `docs/scenarios/` or end-to-end examples in `docs/examples/`.
- **Fix the plugin** — the `/adopt` and `/upgrade` skills in `plugins/aplyca-framework/`.

For anything larger than a focused fix, open an issue first so we can agree on the direction before you invest the time.

## Ground rules

1. **Keep `skeleton/` generic.** No project-specific stacks, paths, conventions, company names, or client names. Agents and skills learn project context from the adopting repo's `AGENTS.md`, `CLAUDE.md`, and rules at runtime — never hardcode it.
2. **Never include real client, customer, or internal project names** anywhere in the repository, including examples, commit messages, and PR descriptions. Use the fictional newsletter feature from `docs/examples/` when you need a concrete example.
3. **Preserve `<!-- CUSTOMIZE -->` markers** in customizable rules and templates; adopting teams rely on them to find what to tailor.
4. **Write in the adopting project's voice** inside `skeleton/`. Files copied into a target repo shouldn't narrate "the framework"; that voice belongs in the root `docs/` only.
5. **Keep always-loaded files lean.** `skeleton/AGENTS.md` and `skeleton/CLAUDE.md` load on every turn in every adopting project, so prefer pointers to detail files over adding bulk there.

## Making a change

1. Fork the repository and create a branch from `main` (`feat/…`, `fix/…`, `docs/…`, `chore/…`).
2. Make one logical change per pull request.
3. **Add a `CHANGELOG.md` entry** under `Unreleased`. Adopting teams upgrade by reading it, so classify every skeleton file you touched against the three-bucket taxonomy in [`docs/UPGRADING.md`](docs/UPGRADING.md): *Overwrite*, *Merge*, or *Additive*. Mark changes that don't land in adopted repos as framework-internal.
4. **Bump the plugin version** in `plugins/aplyca-framework/.claude-plugin/plugin.json` if you changed anything under `plugins/`.
5. Run the checks below.
6. Open a pull request that explains what changed and *why*, and lists the checks you ran.

## Checks

Static evals verify the structural contract of skills, agents, rules, and the spec template. They're deterministic, take milliseconds, and cost no tokens:

```bash
./evals/run-evals.sh
```

If you changed the plugin or marketplace manifests, validate them with Claude Code:

```bash
claude plugin validate .
```

```bash
claude plugin validate plugins/aplyca-framework
```

If you changed how a skill behaves (not just its structure), consider running the relevant dynamic fixture in [`evals/dynamic/`](evals/dynamic/README.md) and noting the result in your PR. Add a new eval only when a real regression surfaces — see [`evals/STRATEGY.md`](evals/STRATEGY.md).

## Commit messages

Use a conventional prefix and the imperative mood, and explain *why* rather than *what*:

```
feat: add observability section to the spec template
fix: resolve skeleton path when the plugin runs from the version cache
docs: add a scenario for dependency upgrades
```

## Code of Conduct and security

Everyone participating is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Please don't report security issues in public issues or pull requests; follow [SECURITY.md](SECURITY.md) instead.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
