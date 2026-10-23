#!/usr/bin/env bash
#
# Sourced by each open-pr case's setup with the run's copy in $work. Leaves, next to the copy, what a
# real delivery would reach — nothing of it leaves the machine:
#   $work.origin.git  the remote: origin is a GitHub address that git rewrites to this bare repository;
#                     its post-receive hook logs each push
#   $work.bin/        put first on the session's PATH by the runner: `gh` (records each call, opens the
#                     pull request, deploys the pushed branch as the preview ~15 s after it opens),
#                     `pnpm` (runs package.json's scripts), and `docker` (no daemon)
#   $work.env         the session's environment: PORT for the local server, REQUEST_LOG
#   $work.events      one line per server start and request, push, gh and docker call: "<epoch> <source> …"
# The preview serves the pushed branch on PORT+1000, from its own export of the remote. A case whose
# setup touches $work.redeploy redeploys it ~10 s after each push once it's up, as a host would.
#
work="${work:?}"
port=$(( 4100 + $(printf '%s' "$work" | cksum | cut -d' ' -f1) % 800 ))
preview_port=$(( port + 1000 ))
events="$work.events"
: > "$events"
printf 'PORT=%s\nREQUEST_LOG=%s\n' "$port" "$events" > "$work.env"
printf '%s %s\n' "$port" "$preview_port" > "$work.ports"
now='python3 -c "import time; print(time.time())"'

git init -q --bare "$work.origin.git"
cat > "$work.origin.git/hooks/post-receive" <<EOF
#!/usr/bin/env bash
while read -r old new ref; do echo "\$($now) push \$ref" >> "$events"; done
if [ -f "$work.redeploy" ] && [ -f "$work.deployed" ]; then
  rm -f "$work.deployed"
  env -u GIT_DIR -u GIT_QUARANTINE_PATH nohup "$work.bin/gh" __redeploy > /dev/null 2>&1 &
fi
EOF
chmod +x "$work.origin.git/hooks/post-receive"
git -C "$work" remote add origin https://github.com/example-org/newsletter-site.git
git -C "$work" config url."$work.origin.git".insteadOf https://github.com/example-org/newsletter-site.git

mkdir -p "$work.bin"
cat > "$work.bin/pnpm" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in install | i) echo "Already up to date"; exit 0 ;; run) shift ;; esac
exec npm run --silent "$@"
EOF
cat > "$work.bin/docker" <<EOF
#!/usr/bin/env bash
echo "\$($now) docker \$*" >> "$events"
echo "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?" >&2
exit 1
EOF
cat > "$work.bin/gh" <<EOF
#!/usr/bin/env bash
work="$work" events="$events" preview_port="$preview_port"
EOF
cat >> "$work.bin/gh" <<'EOF'
case "${1:-}" in __*) ;; *) echo "$(python3 -c 'import time; print(time.time())') gh $*" >> "$events" ;; esac
url=https://github.com/example-org/newsletter-site/pull/42
preview="http://localhost:$preview_port"
save_body() { # the --body-file or --body of a create or edit
  while [ $# -gt 0 ]; do
    case "$1" in
      --body-file | -F) cat "$2" > "$work.pr-body.md"; shift 2 ;;
      --body | -b) printf '%s\n' "$2" > "$work.pr-body.md"; shift 2 ;;
      *) shift ;;
    esac
  done
}
deploy() { # the preview: the pushed branch, exported from the remote, served read-only on its own port
  local branch
  [ -f "$work.done" ] && return  # the run is over
  lsof -ti "tcp:$preview_port" -sTCP:LISTEN 2>/dev/null | xargs kill 2>/dev/null && sleep 1  # a redeploy
  branch="$(git -C "$work" rev-parse --abbrev-ref HEAD)"
  rm -rf "$work.preview" && mkdir -p "$work.preview"
  git -C "$work.origin.git" archive "$branch" | tar -x -C "$work.preview"
  (cd "$work.preview" && PORT="$preview_port" PREVIEW=1 REQUEST_LOG="$events" nohup node app/server.mjs > /dev/null 2>&1 &
   echo $! > "$work.preview.pid")
  touch "$work.deployed"
}
view_json() { # gh pr view --json: every field the cases read, the body as last saved; --jq '.<field>' picks one
  python3 - "$url" "$work.pr-body.md" "$(git -C "$work" rev-parse --abbrev-ref HEAD)" "$@" <<'JSON'
import json, shutil, subprocess, sys
from pathlib import Path
url, body_file, branch, *args = sys.argv[1:]
body = Path(body_file).read_text() if Path(body_file).exists() else ""
pr = {"number": 42, "url": url, "isDraft": True, "state": "OPEN", "title": "newsletter change",
      "body": body, "headRefName": branch, "baseRefName": "main"}
flag = next((f for f in ("--jq", "-q") if f in args), None)
jq = args[args.index(flag) + 1] if flag else ""
if jq[:1] == "." and jq[1:].isidentifier():
    value = pr.get(jq[1:])
    print(value if isinstance(value, str) else json.dumps(value))
elif jq and shutil.which("jq"):
    print(subprocess.run(["jq", "-r", jq], input=json.dumps(pr), text=True, capture_output=True).stdout, end="")
else:
    print(json.dumps(pr))
JSON
}
checks() {
  if [ -f "$work.deployed" ]; then printf 'Preview\tpass\t42s\t%s\tDeployment ready\nCI\tpass\t1m3s\thttps://ci.example.com/runs/42\t\n' "$preview"
  else printf 'Preview\tpending\t0\t\tDeploying\nCI\tpending\t0\thttps://ci.example.com/runs/42\t\n'; fi
}
case "${1:-} ${2:-}" in
  "pr create")
    save_body "$@"
    (sleep 15; deploy) > /dev/null 2>&1 &
    echo "$url" ;;
  "pr edit") save_body "$@"; echo "$url" ;;
  "pr checks")
    if [[ " $* " == *" --watch "* ]]; then
      while [ ! -f "$work.deployed" ]; do sleep 2; done
    fi
    checks ;;
  "pr view")
    if [[ " $* " == *" --json "* ]]; then
      view_json "$@"
    else
      printf 'title:\tnewsletter change\nstate:\tDRAFT\nurl:\t%s\n' "$url"
      [ -f "$work.deployed" ] && printf -- '--\nPreview deployed: %s\n' "$preview"
    fi ;;
  "pr list") printf '42\tnewsletter change\t%s\tDRAFT\n' "$(git -C "$work" rev-parse --abbrev-ref HEAD)" ;;
  "__deploy "*) deploy ;;
  "__redeploy "*) sleep 10; deploy ;;
  "auth status") echo "github.com: Logged in to github.com account dev" ;;
  "repo view") echo "example-org/newsletter-site" ;;
  *) : ;;
esac
EOF
chmod +x "$work.bin/"*
