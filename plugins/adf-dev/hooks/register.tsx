import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { LocalEnvironment } from '../types'
import { chooseUrl, markdownLink, parsePublishedPort, parseService, parseSettings, type Settings } from './local-url'

// The local environment's URL above the prompt, and whether it answers, for the developer's local
// check before the pull request. It reads the project's files, requests the URL, and — when the env
// file pins no APP_PORT — takes the port of the app running on the host (ops/native/.run/app.env, native
// mode, decision 0034), or asks Docker which port it picked for the app with one read-only command,
// `docker compose port <service> <port>` (decision 0032). It never changes, approves, or refuses a
// tool call or a prompt.

const environment = atom({ plugin: 'adf-dev', key: 'localEnvironment' } as const, null)
const EVERY_MS = 15_000
const LOOKUP_MS = 5_000
const WORKTREE_FILES = ['ops/agent/worktree.conf', 'scripts/agent/worktree.conf'] as const

// The last port Docker reported for this checkout's app — null when it reported none, the stack being
// down. It's looked up again after a turn, which may have started or stopped the stack; once a minute;
// and when the URL it gave stops answering. Never on every tick.
type Lookup = { key: string; port: string | null; ticks: number; wasUp: boolean }
let published: Lookup | null = null
const STALE_TICKS = 4 // a minute, at one refresh every 15 seconds

async function settings($: EngineInterface, path: string, keys: readonly string[]): Promise<Settings> {
  try {
    return parseSettings(await $.fs.read(path), keys)
  } catch {
    return {}
  }
}

async function answers($: EngineInterface, url: string): Promise<boolean> {
  // Any answer, a 404 or a 500 included, means something is listening there.
  return $.http.fetch(url).then(
    () => true,
    () => false,
  )
}

// The parallel-agents module's settings: ops/agent/, or scripts/agent/ before the module moved.
async function worktreeSettings($: EngineInterface, root: string): Promise<{ values: Settings; file: string }> {
  for (const file of WORKTREE_FILES) {
    try {
      return { values: parseSettings(await $.fs.read(`${root}/${file}`), ['READY_URL', 'ENV_FILE']), file }
    } catch {
      // Not in this folder; try the next one.
    }
  }
  return { values: {}, file: WORKTREE_FILES[0] }
}

// The host port Docker gave the app's service. The one process this mod runs: a fixed argument
// vector, no shell, read-only, and only for a service and port parseService accepted.
async function publishedPort($: EngineInterface, root: string, service: string, isFresh: boolean): Promise<Lookup | null> {
  const target = parseService(service)
  if (!target) {
    return null
  }
  const key = `${root} ${service}`
  if (!isFresh && published?.key === key && published.ticks < STALE_TICKS) {
    published.ticks += 1
    return published
  }
  let port: string | null = null
  try {
    const { exitCode, stdout } = await $.process.run(['docker', 'compose', 'port', target.service, target.port], {
      cwd: root,
      timeoutMs: LOOKUP_MS,
    })
    port = exitCode === 0 ? parsePublishedPort(stdout) : null
  } catch {
    port = null
  }
  published = { key, port, ticks: 0, wasUp: false }
  return published
}

async function refresh($: EngineInterface, isFresh = false): Promise<LocalEnvironment | null> {
  const root = await $.session.root()
  const config = await settings($, `${root}/.claude/hooks/config.sh`, ['LOCAL_URL', 'LOCAL_SERVICE'])
  const worktree = await worktreeSettings($, root)
  // Only APP_PORT is kept from the env file; nothing else in it is read into the mod.
  const env = await settings($, `${root}/${worktree.values.ENV_FILE || '.env'}`, ['APP_PORT'])
  const locate = async (values: Settings, note: string): Promise<LocalEnvironment | null> => {
    const source = chooseUrl(config, worktree.values, values, worktree.file)
    return source ? { url: source.url, from: source.from + note, isUp: await answers($, source.url) } : null
  }
  // The app on the host (DEV_MODE=native): ops/native/native.sh keeps its port there while it runs.
  const host = env.APP_PORT ? {} : await settings($, `${root}/ops/native/.run/app.env`, ['APP_PORT'])
  let found: LocalEnvironment | null
  if (env.APP_PORT || !config.LOCAL_SERVICE) {
    found = await locate(env, '')
  } else if (host.APP_PORT) {
    found = await locate(host, ', the app on the host')
  } else {
    // No port pinned: the one Docker picked, which changes each time the service starts.
    const viaDocker = async (lookup: Lookup | null) =>
      lookup?.port ? locate({ ...env, APP_PORT: lookup.port }, ', port from docker compose port') : null
    let lookup = await publishedPort($, root, config.LOCAL_SERVICE, isFresh)
    found = await viaDocker(lookup)
    if (lookup?.wasUp && !found?.isUp) {
      // It stopped answering: Docker may have started it again on another port.
      lookup = await publishedPort($, root, config.LOCAL_SERVICE, true)
      found = await viaDocker(lookup)
    }
    if (lookup) {
      lookup.wasUp = found?.isUp ?? false
    }
  }
  await update($, environment, () => found)
  return found
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'local-url',
      description: "Show this checkout's local environment URL, and whether it answers",
    })
    // Off the session's start, so a slow server never holds the first prompt.
    $.clock.after(0, () => void refresh($))
    $.clock.every(EVERY_MS, () => void refresh($))

    return next(e)
  })

  // A turn may have started or stopped the app, or moved the session into a worktree.
  on('turn.complete', async ($, e, next) => {
    $.clock.after(0, () => void refresh($, true))

    return next(e)
  })

  on('command.run', { command: 'local-url' }, async $ => {
    const found = await refresh($)
    if (!found) {
      return {
        text: 'No local URL. Set LOCAL_URL in .claude/hooks/config.sh (and LOCAL_SERVICE for a port Docker picks), or READY_URL in ops/agent/worktree.conf with the parallel-agents module.',
      }
    }

    return { text: `${found.url} is ${found.isUp ? 'answering' : 'not answering'} (from ${found.from}).` }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const found = await read($, environment)
    if (found === null || e.props.hasSurvey) {
      return next(e)
    }
    const { Box, Markdown, Text } = $.ui.resolve(e)

    // A Markdown link, not a Link: the desktop app draws a Link plain unless it's https:, and a local
    // URL is usually http:. The surface opens it as it opens any link in a reply.
    return (
      <Box>
        <Text color={found.isUp ? 'success' : 'inactive'}>{found.isUp ? '● ' : '○ '}</Text>
        <Text dimColor>Local: </Text>
        <Markdown text={markdownLink(found.url)} />
        {found.isUp ? null : <Text dimColor> · not answering</Text>}
      </Box>
    )
  })
}
