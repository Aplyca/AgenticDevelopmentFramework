#!/usr/bin/env bash
#
# prod-build: the fast lane's light CR 2 — the email label reads "Your email" — on a project with the
# docker module, configured for Docker mode, whose production build renders the page at build time.
# The "done when" names the production build, so the local check needs `make prod` (dev-env C11).
# package.json still has `build` and `start`, which a host server would use. Nothing is pushed.
#
# docker is a stand-in (compose.py, beside it in $work.bin/): Compose for this stack without a daemon.
# Its "containers" run on this machine, tagged WHERE=container (web, the dev server, on PORT) and
# WHERE=container-prod (web-prod, built from a copy of the working tree, on PORT+500); a server
# started any other way logs as "local", which is how inspect.sh tells a host server apart.
#
set -euo pipefail
work="$1"
FW="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$(dirname "$0")/stubs.sh"
cd "$work"
TPL="$FW/plugins/adf-dev/skills/dev-env/templates"

# The app: the production build renders the page into dist/ at build time, and serves it from there.
mkdir -p scripts
cat > scripts/build.mjs <<'JS'
import { mkdirSync, writeFileSync } from 'node:fs';
import { page } from '../app/page.mjs';

mkdirSync('dist', { recursive: true });
writeFileSync('dist/index.html', page());
console.log('Built dist/index.html');
JS
python3 - <<'PY'
import json
from pathlib import Path
p = Path("app/server.mjs"); s = p.read_text()
for old, new in [
    ("import { appendFileSync } from 'node:fs';", "import { appendFileSync, readFileSync } from 'node:fs';"),
    ("const where = process.env.PREVIEW ? 'preview' : 'local';",
     "const where = process.env.WHERE || (process.env.PREVIEW ? 'preview' : 'local');"),
    ("export async function render() {\n  return page();",
     "export async function render() {\n  if (process.env.NODE_ENV === 'production') return readFileSync('dist/index.html', 'utf8');\n  return page();"),
]:
    assert old in s, old
    s = s.replace(old, new, 1)
p.write_text(s)
p = Path("package.json"); d = json.loads(p.read_text())
d["scripts"].update({"build": "node scripts/build.mjs", "start": "NODE_ENV=production node app/server.mjs"})
p.write_text(json.dumps(d, indent=2) + "\n")
PY
printf 'dist/\n' >> .gitignore

# The local environment, from dev-env's templates, filled for this stack.
cp "$TPL/Makefile" Makefile && cp -R "$TPL/ops" ops && printf 'ops/native/.run/\n' >> .gitignore
cat > compose.yaml <<'YAML'
services:
  web:
    build:
      context: .
      dockerfile: ops/docker/web/Dockerfile
      target: dev
    ports:
      - "127.0.0.1:${APP_PORT:-}:3000"
    environment:
      PORT: "3000"
    volumes:
      - .:/app

  # The production build, served beside the dev server by `make prod` only.
  web-prod:
    profiles: [prod]
    build:
      context: .
      dockerfile: ops/docker/web/Dockerfile
      target: prod
    ports:
      - "127.0.0.1:${APP_PROD_PORT:-}:3000"
    environment:
      PORT: "3000"
YAML
cat > .env.example <<'ENV'
DEV_MODE=
SERVICES=
COMPOSE_PROJECT_NAME=
APP_PORT=
APP_PROD_PORT=
DATABASE_URL=
MAILCHIMP_API_KEY=
ENV
python3 - <<'PY'
from pathlib import Path
def fill(path, pairs):
    p = Path(path); s = p.read_text()
    for old, new in pairs:
        assert old in s, (path, old[:60])
        s = s.replace(old, new, 1)
    p.write_text(s)
fill("ops/docker/web/Dockerfile", [
    ("FROM <image>:<version> AS dev", "FROM node:22.18-alpine AS dev"),
    ("COPY <manifests> ./\nRUN <install command>", "COPY package.json ./\nRUN true"),
    ('CMD ["<dev command>"]', 'CMD ["node", "app/server.mjs"]'),
    ("RUN <build command>", "RUN node scripts/build.mjs\nENV NODE_ENV=production"),
    ('CMD ["<production server command>"]', 'CMD ["node", "app/server.mjs"]'),
])
fill("ops/docker/Makefile", [
    ('\t@echo "CUSTOMIZE: the test command, with t as its filter, e.g. $(COMPOSE) exec -T $(APP) <test command> $(t)" >&2; exit 1',
     '\t$(COMPOSE) exec -T $(APP) node --test $(t)'),
    ('\t@echo "CUSTOMIZE: the lint command, with f as its files, e.g. $(COMPOSE) exec -T $(APP) <lint command> $(f)" >&2; exit 1',
     '\t$(COMPOSE) exec -T $(APP) node --check $(or $(f),app/server.mjs)'),
    ('\t@echo "CUSTOMIZE: the format command, e.g. $(COMPOSE) exec -T $(APP) <format command> $(f) — or say the stack has no formatter" >&2; exit 1',
     '\t@echo "This stack has no formatter"'),
    ('\t@echo "CUSTOMIZE: the type checker, e.g. $(COMPOSE) exec -T $(APP) <type check command> — or say the stack has none" >&2; exit 1',
     '\t$(COMPOSE) exec -T $(APP) node --check lib/validate-email.mjs'),
])
fill("ops/native/Makefile", [
    ("DEFAULT_SERVICES = redis", "DEFAULT_SERVICES ="),
    ('NATIVE_CMD = echo "CUSTOMIZE: set NATIVE_CMD in ops/native/Makefile to the app\'s dev command" >&2; exit 1',
     'NATIVE_CMD = PORT="$$APP_PORT" exec node app/server.mjs'),
    ('NATIVE_PROD_CMD = echo "CUSTOMIZE: set NATIVE_PROD_CMD in ops/native/Makefile to the production build and server" >&2; exit 1',
     'NATIVE_PROD_CMD = node scripts/build.mjs && NODE_ENV=production PORT="$$APP_PORT" exec node app/server.mjs'),
])
fill("AGENTS.md", [
    ("modules: none", "modules: docker"),
    ("- Dev server: `pnpm dev` · stop: Ctrl-C · where it runs: `pnpm urls`",
     "- Dev server: `make up` · stop: `make down` · where it runs: `make urls`"),
    ('- Production build, locally: `none`', '- Production build, locally: `make prod`'),
    ("- Tests: `pnpm test`", "- Tests: `make test` (t=<file>)"),
    ("- Lint: `pnpm lint` · Typecheck: `pnpm typecheck`", "- Lint: `make lint` · Typecheck: `make typecheck`"),
    ("- Full gate before a PR: `pnpm lint && pnpm typecheck && pnpm test`",
     "- Full gate before a PR: `make lint && make typecheck && make test`"),
])
PY
"$FW/modules/docker/install.sh" . >/dev/null
make env >/dev/null
shasum .env > "$work.env-sum"
git add -A && git commit -q -m "chore: the local environment in Docker, with the production build (dev-env)"

# The change, committed on its work branch.
git switch -q -c fix/newsletter-email-label
sed -i.bak "s/emailLabel: 'Email address'/emailLabel: 'Your email'/" components/newsletter-copy.mjs
sed -i.bak 's/>Email address</>Your email</' tests/newsletter-form.test.mjs
rm -f components/*.bak tests/*.bak
cat >> specs/007-newsletter-signup/spec.md <<'SPEC'

# CR 2 — The email field's label reads "Your email" (2026-10-18) · light

- **Requested:** https://tracker.example.com/t/MKT-530 · by marketing

| Aspect | Delivered (PR 142) | Change |
| --- | --- | --- |
| Email field label | "Email address", fixed text | "Your email", fixed text |

Done when the production build shows "Your email" and the label test passes.
SPEC
git add -A && git commit -q -m 'fix(newsletter): the email label reads "Your email" (CR 2)'
git rev-parse HEAD > "$work.setup-head"

# docker: the Compose stand-in.
cp "$(dirname "$0")/compose-stub.py" "$work.bin/compose.py"
cat > "$work.bin/docker" <<EOF
#!/usr/bin/env bash
STUB_WORK="$work" exec python3 "$work.bin/compose.py" "\$@"
EOF
chmod +x "$work.bin/docker"
