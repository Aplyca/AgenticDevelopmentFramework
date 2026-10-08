# Contributing to the Agentic Development Framework

Thanks for helping improve the framework. This repository is not an application — it is a portable skeleton, optional modules, documentation, and the `aplyca-adf` Claude Code plugin. Its "code" is mostly prompts, rules, and templates that end up inside other teams' repositories, so a one-line change here changes how many AI agents behave. The guidelines below exist to keep those changes safe to adopt.

## Ways to contribute

- **Report a problem** — open an issue describing what you expected, what the AI or the template did instead, and which tool you used (Claude Code, Cursor, Copilot, Antigravity, …).
- **Improve the skeleton** — clearer rules, better skill instructions, missing spec sections, hooks, tool-compatibility fixes.
- **Improve a module** — or propose a new one in `modules/` for harness that depends on a Git host or a way of working.
- **Add worked material** — new playbooks in `docs/scenarios/` or end-to-end examples in `docs/examples/`.
- **Fix the plugin** — the `/adopt` and `/upgrade` skills in `plugins/aplyca-adf/`.

For anything larger than a focused fix, open an issue first so we can agree on the direction before you invest the time.

## Ground rules

1. **Keep `skeleton/` and `modules/*/files/` generic.** No project-specific stacks, paths, conventions, company names, or client names. Agents and skills learn project context from the adopting repo's `AGENTS.md`, `CLAUDE.md`, and rules at runtime — never hardcode it.
2. **Never include real client, customer, or internal project names** anywhere in the repository, including examples, commit messages, and PR descriptions. Use the fictional newsletter feature from `docs/examples/` when you need a concrete example.
3. **Preserve `<!-- CUSTOMIZE -->` markers** in customizable rules and templates; adopting teams rely on them to find what to tailor.
4. **Write in the adopting project's voice** inside `skeleton/`. Files copied into a target repo shouldn't narrate "the framework"; that voice belongs in the root `docs/` only.
5. **Keep always-loaded files lean.** `skeleton/AGENTS.md` and `skeleton/CLAUDE.md` load on every turn in every adopting project, so prefer pointers to detail files over adding bulk there (the static checks fail `AGENTS.md` over 200 lines).
6. **Use documented configuration only.** Hyphenated skill and agent frontmatter keys (unknown keys are silently ignored), nested `hooks` arrays in `settings.json`, hooks that read the event from stdin. Verify against the Claude Code docs when in doubt — several past defects were configuration that looked right and silently never ran.
7. **Never link from the skeleton to framework-only docs.** Adopting repos get the skeleton without `docs/`, `evals/`, or `modules/`; the link check fails on such links.
8. **Record significant design decisions** in `docs/decisions/` — context with evidence, decision, consequences including the cost, alternatives.

## Making a change

1. Fork the repository and create a branch from `main` (`feat/…`, `fix/…`, `docs/…`, `chore/…`).
2. Make one logical change per pull request.
3. **Add a `CHANGELOG.md` entry** under `Unreleased`. Adopting teams upgrade by reading it, so classify every skeleton file you touched against the three-bucket taxonomy in [`docs/UPGRADING.md`](docs/UPGRADING.md): *Overwrite*, *Merge*, or *Additive*. Mark changes that don't land in adopted repos as framework-internal.
4. **Bump the plugin version** in `plugins/aplyca-adf/.claude-plugin/plugin.json` if you changed anything under `plugins/`.
5. Run the checks below.
6. Open a pull request that explains what changed and *why*, and lists the checks you ran.

**Cutting a release** (maintainers): when `Unreleased` holds changes adopting teams should take, pick
the version by [decision 0017](docs/decisions/0017-semantic-versioning.md): MAJOR when a team has to
act, MINOR for additive or opt-in capabilities, PATCH for fixes. In one pull request, rename
`Unreleased` to `## vX.Y.Z — <date> — <title>`, open it with the order to upgrade in when it spans
several parts, add an empty `Unreleased` above it, and set `"version"` in
`plugins/aplyca-adf/.claude-plugin/plugin.json` to `X.Y.Z` (a static check holds the two equal). Once
it merges, tag the merge commit `vX.Y.Z` and push the tag: packaged projects pin it, and without it
they can't take the release.

**The machinery in `plugins/aplyca-adf/` is generated** from `skeleton/.claude/` by
`scripts/build-plugins.sh` — every path its `.generated` file lists. Never edit those; after any change under `skeleton/.claude/`, run the script and commit its output with
the change. The static checks fail when the two drift apart.

## Checks

The static suites verify the structural contract of skills, agents, workflows, rules, settings, hooks, templates, links, and modules, and functionally test the hooks and module scripts in throwaway repositories. They're deterministic, take seconds, and cost no tokens (they need `bash`, `git`, `python3`, and `node` for the workflow syntax check):

```bash
./evals/run-evals.sh
```

Changed a hook or a module script? Add a case to `evals/static/test-hooks.sh` or `test-modules.sh` that feeds it the input you changed.

If you changed the plugin or marketplace manifests, validate them with Claude Code:

```bash
claude plugin validate .
```

```bash
claude plugin validate plugins/aplyca-adf
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
