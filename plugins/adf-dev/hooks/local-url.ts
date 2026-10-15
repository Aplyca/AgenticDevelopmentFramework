// Where the local environment's URL comes from, in the files a project already keeps:
// `LOCAL_URL` in .claude/hooks/config.sh, or, with the parallel-agents module, `READY_URL` in
// ops/agent/worktree.conf (scripts/agent/ before the module moved). Either may name ${APP_PORT}: the
// env file's when it pins one, else the port Docker picked for `LOCAL_SERVICE`, which the band looks
// up (decision 0032). The files are data: read line by line as KEY=value, never run.

export type Settings = Readonly<Record<string, string>>

export type Source = { url: string; from: string }

// KEY=value lines, as the framework's shell settings write them: double- or single-quoted or bare,
// indentation and trailing comments allowed. Only the keys asked for are kept.
export function parseSettings(text: string, keys: readonly string[]): Settings {
  const found: Record<string, string> = {}
  for (const raw of text.split('\n')) {
    const match = /^([A-Z_][A-Z0-9_]*)=(.*)$/.exec(raw.trim())
    const key = match?.[1]
    if (key === undefined || !keys.includes(key)) {
      continue
    }
    const value = match?.[2] ?? ''
    if (value.startsWith('"')) {
      found[key] = value.slice(1).split('"')[0] ?? ''
    } else if (value.startsWith("'")) {
      found[key] = value.slice(1).split("'")[0] ?? ''
    } else {
      found[key] = value.split(/\s/)[0] ?? ''
    }
  }
  return found
}

// Fills each ${NAME} from `values`; null when the template names a value that isn't there, such as
// ${APP_PORT} in a checkout that has no port.
export function expand(template: string, values: Settings): string | null {
  let isMissing = false
  const text = template.replace(/\$\{([A-Z_][A-Z0-9_]*)\}/g, (_, name: string) => {
    const value = values[name]
    if (!value) {
      isMissing = true
    }
    return value ?? ''
  })
  return isMissing ? null : text
}

function httpUrl(text: string | null): string | null {
  if (!text) {
    return null
  }
  try {
    const { protocol } = new URL(text)
    return protocol === 'http:' || protocol === 'https:' ? text : null
  } catch {
    return null
  }
}

// `[url](url)`, with the characters Markdown reads as syntax escaped: brackets in the text (an IPv6
// host), parentheses and spaces in the target.
export function markdownLink(url: string): string {
  const text = url.replace(/[[\]\\]/g, ch => `\\${ch}`)
  const target = url.replace(/[()\s]/g, ch => encodeURIComponent(ch).replace('(', '%28').replace(')', '%29'))
  return `[${text}](${target})`
}

// The project's own LOCAL_URL wins; otherwise the worktree's READY_URL, from the file it was read
// from; otherwise there's none.
export function chooseUrl(
  config: Settings,
  worktree: Settings,
  env: Settings,
  worktreeFile = 'ops/agent/worktree.conf',
): Source | null {
  const declared = httpUrl(config.LOCAL_URL ? expand(config.LOCAL_URL, env) : null)
  if (declared) {
    return { url: declared, from: '.claude/hooks/config.sh' }
  }
  const ready = httpUrl(worktree.READY_URL ? expand(worktree.READY_URL, env) : null)
  if (ready) {
    return { url: ready, from: worktreeFile }
  }
  return null
}

export type Service = { service: string; port: string }

// `LOCAL_SERVICE`, the app's Compose service and container port: `web:3000`. Anything else is null,
// so nothing but a service name and a number ever reaches the lookup's argument vector.
export function parseService(text: string | undefined): Service | null {
  const match = /^([a-z0-9][a-z0-9_.-]*):([0-9]{1,5})$/.exec(text ?? '')
  return match?.[1] && match[2] ? { service: match[1], port: match[2] } : null
}

// What `docker compose port <service> <port>` prints, `127.0.0.1:50916` or `[::1]:50916`: the host
// port, or null.
export function parsePublishedPort(stdout: string): string | null {
  const line = stdout.trim().split('\n').pop() ?? ''
  const port = /:([0-9]{1,5})$/.exec(line)?.[1]
  return port && Number(port) > 0 && Number(port) < 65536 ? port : null
}
