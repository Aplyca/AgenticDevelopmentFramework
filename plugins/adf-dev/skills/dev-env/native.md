# Native mode — the app on the host

`/adf-dev:dev-env` reads this for the native mode (step 4), with
`<this skill's base directory>/SPECIFICATION.md`: the app on the host, or switching between the two.

Where the app runs is a setting, not a different command. The root `Makefile` loads
`ops/<DEV_MODE>/Makefile`, and both mode files define the same tasks (C2, C3): `ops/docker/Makefile`
runs the whole stack in Docker (M4); `ops/native/Makefile` runs the app on the host with the stack's
own dev command, its backing services in Docker (M5).

1. **Choose the mode** — M1 says where it's set, and only the developer changes it (M10, and
   `SKILL.md` § Safety). A checkout's own choice is `DEV_MODE` in its `.env` — the developer's file,
   which they edit; never read it into the conversation. `make help` names the mode and the file in
   force.
2. **What native mode needs,** in `ops/native/Makefile` (M5):
   - `NATIVE_CMD` and the `deps`, `test`, and `lint` commands on the host, from the package
     manifest, the README, or the project's docs; `NATIVE_PROD_CMD`, when the project has
     `make prod` (C11). Setting them is a change to the stack, through triage.
   - `DEFAULT_SERVICES`. A developer's own `SERVICES`, and the ports they pin, go in their `.env`,
     which they edit.
   - The stack's runtime on the host, at the version the project pins — a prerequisite row in
     `DEV-SETUP.md`.
   - The host-form variables in `.env` (V1). For a stack whose env loader doesn't expand `${…}`,
     `NATIVE_CMD` passes them itself.
3. **Start it — when this checkout is configured for native mode.** When it isn't, don't switch it:
   read `ops/native/Makefile` against M4–M8, and give the developer the setting to change
   (`DEV_MODE=native` in their `.env`) and steps 3 and 5 to run, or to ask for once they've switched.
   `make up` starts it as M6 says, with the ports P4 exports, and stops the app's container (M8);
   `make stop` and `make down` end its process group (M6); `make logs` shows its log.
4. **Switching modes** is the developer's, and needs no cleanup (M8).
5. **Verify:** `make ps` shows the app on the host and only the backing services in Docker; the app
   answers on the URL `make urls` gives; the quickest test that needs the stack passes with
   `make test`. `ops/docker/launch-json.sh` reads the app's port from `ops/native/.run/app.env` (P8).
