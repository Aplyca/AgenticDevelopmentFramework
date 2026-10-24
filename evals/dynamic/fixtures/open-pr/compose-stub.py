#!/usr/bin/env python3
#
# The prod-build case's `docker`: Docker Compose for its stack, with no daemon. prod-build.setup.sh
# copies it beside the run's copy, and the `docker` there runs it with STUB_WORK set to the copy.
#
# Two services: web, the dev server, on the case's PORT; web-prod, in the prod profile, built from a
# copy of the working tree with `node scripts/build.mjs` and served with NODE_ENV=production, on
# PORT+500. Each "container" is a node process on this machine, tagged WHERE=container or
# WHERE=container-prod in the request log; its pid, port, and log are in <copy>.compose/. It answers
# what the dev-env Makefile and native.sh ask — up, ps (with the formats they use), logs, stop, down,
# exec, build — and logs every call to <copy>.events.
#
import os, re, shutil, signal, socket, subprocess, sys, time
from pathlib import Path

work = os.environ["STUB_WORK"]
events = work + ".events"
state = Path(work + ".compose")
state.mkdir(exist_ok=True)
base_port = int(Path(work + ".ports").read_text().split()[0])
SERVICES = {"web": base_port, "web-prod": base_port + 500}
PROFILED = {"web-prod"}

with open(events, "a") as f:
    f.write(f"{time.time()} docker {' '.join(sys.argv[1:])}\n")


def listening(port):
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def pid_of(service):
    p = state / f"{service}.pid"
    if not p.exists():
        return None
    pid = int(p.read_text())
    try:
        os.kill(pid, 0)
        return pid
    except OSError:
        p.unlink()
        return None


def stop(service):
    pid = pid_of(service)
    if pid:
        os.killpg(pid, signal.SIGTERM)
        for _ in range(20):
            if not listening(SERVICES[service]):
                break
            time.sleep(0.25)
        (state / f"{service}.pid").unlink(missing_ok=True)
        print(f" Container newsletter-site-{service}-1  Stopped", file=sys.stderr)


def start(service):
    port = SERVICES[service]
    if service == "web-prod":
        image = Path(work + ".prod-image")
        shutil.rmtree(image, ignore_errors=True)
        shutil.copytree(work, image, ignore=shutil.ignore_patterns(".git", "node_modules", "dist", ".env"))
        print(f" Image newsletter-site-{service} Building", file=sys.stderr)
        built = subprocess.run(["node", "scripts/build.mjs"], cwd=image, capture_output=True, text=True)
        if built.returncode != 0:
            sys.exit(f"failed to solve: process \"node scripts/build.mjs\" did not complete successfully:\n{built.stderr}")
        cwd, env = image, {"NODE_ENV": "production", "WHERE": "container-prod"}
    else:
        cwd, env = Path(work), {"WHERE": "container"}
    log = open(state / f"{service}.log", "a")
    proc = subprocess.Popen(["node", "app/server.mjs"], cwd=cwd, stdout=log, stderr=log, start_new_session=True,
                            env={**os.environ, **env, "PORT": str(port), "REQUEST_LOG": events})
    (state / f"{service}.pid").write_text(str(proc.pid))
    for _ in range(60):
        if listening(port):
            break
        time.sleep(0.25)
    print(f" Container newsletter-site-{service}-1  Healthy", file=sys.stderr)


def running():
    return [s for s in SERVICES if pid_of(s)]


def render(fmt, service):
    port = SERVICES[service]
    if "PublishedPort" in fmt:
        inner = re.search(r"\{\{if \.PublishedPort\}\}(.*?)\{\{end\}\}", fmt)
        return (inner.group(1) if inner else "{{.PublishedPort}}").replace("{{.PublishedPort}}", str(port))
    return f"{service}\t127.0.0.1:{port}->3000/tcp\tUp"


args = sys.argv[1:]
if args[:1] != ["compose"]:
    if args[:1] in (["version"], ["--version"], ["info"]):
        print("Docker version 29.0.0 (stand-in)")
    sys.exit(0)
args = args[1:]
profiles = set()
while args and args[0] in ("--profile", "-p", "-f"):
    if args[0] == "--profile":
        profiles.add(args[1])
    args = args[2:]
cmd, rest = (args[0], args[1:]) if args else ("", [])
fmt = rest[rest.index("--format") + 1] if "--format" in rest else ""
named, i = [], 0  # the services named, past the flags and their values; exec's command isn't one
while i < len(rest):
    if rest[i] in ("--format", "--tail"):
        i += 2
        continue
    if not rest[i].startswith("-"):
        named.append(rest[i])
        if cmd == "exec":
            break
    i += 1
for s in named:
    if s not in SERVICES:
        sys.exit(f"no such service: {s}")

if cmd == "up":
    for s in named or [s for s in SERVICES if s not in PROFILED or s in profiles]:
        if s in PROFILED and "prod" not in profiles:
            sys.exit(f"service {s} is not enabled by the active profiles")
        if pid_of(s) and ("--build" not in rest and "--force-recreate" not in rest):
            continue
        stop(s)
        start(s)
elif cmd == "ps":
    if named:
        s = named[0]
        if pid_of(s):
            print(render(fmt, s))
    else:
        print("SERVICE\tPORTS\tSTATUS")
        for s in running():
            print(render("", s))
elif cmd == "logs":
    tail = int(rest[rest.index("--tail") + 1]) if "--tail" in rest else 100
    for s in named or list(SERVICES):
        log = state / f"{s}.log"
        if log.exists():
            for line in log.read_text().splitlines()[-tail:]:
                print(f"{s}-1  | {line}")
elif cmd in ("stop", "down", "kill", "rm"):
    for s in named or list(SERVICES):
        stop(s)
elif cmd == "exec":
    sys.exit(subprocess.run(rest[rest.index(named[0]) + 1:], cwd=work).returncode)
elif cmd == "build":
    print(" Image newsletter-site-web Built", file=sys.stderr)
sys.exit(0)
