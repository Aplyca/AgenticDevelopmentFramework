# 0060: The local-environment band is retired — Claude Desktop's Browser lists the running app

- **Status:** accepted
- **Date:** 2026-10-28
- **Supersedes:** [0026](0026-display-only-mods.md) — the only mod; [0032](0032-local-environment-layout.md)'s
  `docker compose port` exception for it

## Context

The `adf-dev` mod showed the local URL above the prompt and whether it answered. Since 0056, Claude
Desktop's Browser lists each checkout's running web services, from `.claude/launch.json` written by
the environment's own scripts. The band is redundant there, and adds code that runs unsandboxed in the
developer's session.

## Decision

Remove the mod (`hooks/`, `types/`, `tests/`), its static check and test run, and `LOCAL_SERVICE`
(only the band read it). `LOCAL_URL` stays: the agent walks it in the local check. `adf-dev` carries
skills only.

## Consequences

- Terminal users no longer see the URL above the prompt; `make urls` and `LOCAL_URL` remain.
- `/adf:adopt` and `/adf:upgrade` stop offering the band.
