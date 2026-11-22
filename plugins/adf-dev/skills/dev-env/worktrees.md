# Worktrees — one stack per worktree

`/adf-dev:dev-env` reads this for the worktrees mode (step 4), with
`<this skill's base directory>/SPECIFICATION.md`, whose § Worktrees (W1–W3) this mode checks:
parallel worktrees whose stacks collide.

Needs the parallel-agents module (`ops/agent/worktree.conf`, or `scripts/agent/worktree.conf`
before it moved); without it, say so and stop.

1. **Audit isolation (W1–W3).** A stack that meets the specification already runs once per
   worktree: the worktree's folder names its Compose project, and Docker picks its ports. What
   breaks that: a top-level `name:`, a `container_name:`, a fixed host port in `compose.yaml` —
   set up's migration fixes those — or a port or `COMPOSE_PROJECT_NAME` the main checkout's `.env`
   pins, which every worktree's copy repeats.
2. **Propose the `worktree.conf` values W2 gives** — an infrastructure change the developer
   approves — and `.env` in `.worktreeinclude` when it holds what the stack needs. Why each value,
   where W2 doesn't say:
   - `PORT_SLOTS=0` — the ports are Docker's, so the scripts reserve none;
   - `ENV_OVERRIDES` — each worktree's project gets a clear name, and its ports stay Docker's;
   - `SETUP_CMD` — never a host install (`npm ci`), which Docker mode never uses: its tests and
     checks run in the tools container (M11);
   - `START_CMD` — in the worktree's mode, which its `.env` sets (W3);
   - `STOP_CMD` — it stops an app running on the host, then removes only this worktree's project,
     since its `COMPOSE_PROJECT_NAME` is that worktree's. `make down` instead keeps data that's
     costly to rebuild;
   - `READY_URL` empty — `make up` already waits until every service is healthy, or the app on the
     host answers;
   - `ENV_INFO_CMD` — so `adf-worktree-ls --info` shows where each worktree's services are.
3. **Verify in a worktree:** `adf-worktree-new <branch>` starts it; `docker compose ls` shows its
   project beside another worktree's; `adf-worktree-ls --info` shows each one's ports; the app
   answers on its own. A worktree whose `.env` repeats the main checkout's pinned values stops at
   `make up`, naming the lines to empty.
4. **Record** in `docs/SHARED-SERVICES.md` what worktrees share, what each one
   copies, and what a copy costs.
