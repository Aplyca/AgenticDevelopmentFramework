// Where the local environment's URL comes from, in the files a project already keeps:
// `LOCAL_URL` in .claude/hooks/config.sh, or, with the parallel-agents module, `READY_URL` in
// scripts/agent/worktree.conf. Either may name ${APP_PORT}, which the worktree's env file holds. The
// files are data: read line by line as KEY=value, never run.

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

// The project's own LOCAL_URL wins; otherwise the worktree's READY_URL; otherwise there's none.
export function chooseUrl(config: Settings, worktree: Settings, env: Settings): Source | null {
  const declared = httpUrl(config.LOCAL_URL ? expand(config.LOCAL_URL, env) : null)
  if (declared) {
    return { url: declared, from: '.claude/hooks/config.sh' }
  }
  const ready = httpUrl(worktree.READY_URL ? expand(worktree.READY_URL, env) : null)
  if (ready) {
    return { url: ready, from: 'scripts/agent/worktree.conf' }
  }
  return null
}
