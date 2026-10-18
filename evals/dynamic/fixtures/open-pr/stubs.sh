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
# The preview serves the pushed branch on PORT+1000, from its own export of the remote.
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
echo "$(python3 -c 'import time; print(time.time())') gh $*" >> "$events"
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
  branch="$(git -C "$work" rev-parse --abbrev-ref HEAD)"
  rm -rf "$work.preview" && mkdir -p "$work.preview"
  git -C "$work.origin.git" archive "$branch" | tar -x -C "$work.preview"
  (cd "$work.preview" && PORT="$preview_port" PREVIEW=1 REQUEST_LOG="$events" nohup node app/server.mjs > /dev/null 2>&1 &
   echo $! > "$work.preview.pid")
  touch "$work.deployed"
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
      printf '{"number":42,"url":"%s","isDraft":true,"state":"OPEN","title":"newsletter change"}\n' "$url"
    else
      printf 'title:\tnewsletter change\nstate:\tDRAFT\nurl:\t%s\n' "$url"
      [ -f "$work.deployed" ] && printf -- '--\nPreview deployed: %s\n' "$preview"
    fi ;;
  "pr list") printf '42\tnewsletter change\t%s\tDRAFT\n' "$(git -C "$work" rev-parse --abbrev-ref HEAD)" ;;
  "auth status") echo "github.com: Logged in to github.com account dev" ;;
  "repo view") echo "example-org/newsletter-site" ;;
  *) : ;;
esac
EOF
chmod +x "$work.bin/"*
