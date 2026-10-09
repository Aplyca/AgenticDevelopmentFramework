import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { LocalEnvironment } from '../types'
import { chooseUrl, markdownLink, parseSettings, type Settings } from './local-url'

// The local environment's URL above the prompt, and whether it answers, for the developer's local
// check before the pull request. It only reads three of the project's files and requests the URL:
// it never changes, approves, or refuses a tool call or a prompt.

const environment = atom({ plugin: 'adf-dev', key: 'localEnvironment' } as const, null)
const EVERY_MS = 15_000

async function settings($: EngineInterface, path: string, keys: readonly string[]): Promise<Settings> {
  try {
    return parseSettings(await $.fs.read(path), keys)
  } catch {
    return {}
  }
}

async function refresh($: EngineInterface): Promise<LocalEnvironment | null> {
  const root = await $.session.root()
  const config = await settings($, `${root}/.claude/hooks/config.sh`, ['LOCAL_URL'])
  const worktree = await settings($, `${root}/scripts/agent/worktree.conf`, ['READY_URL', 'ENV_FILE'])
  // Only APP_PORT is kept from the env file; nothing else in it is read into the mod.
  const env = await settings($, `${root}/${worktree.ENV_FILE || '.env'}`, ['APP_PORT'])
  const source = chooseUrl(config, worktree, env)
  let found: LocalEnvironment | null = null
  if (source) {
    // Any answer, a 404 or a 500 included, means something is listening there.
    const isUp = await $.http.fetch(source.url).then(
      () => true,
      () => false,
    )
    found = { ...source, isUp }
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
    $.clock.after(0, () => void refresh($))

    return next(e)
  })

  on('command.run', { command: 'local-url' }, async $ => {
    const found = await refresh($)
    if (!found) {
      return {
        text: 'No local URL. Set LOCAL_URL in .claude/hooks/config.sh, or READY_URL in scripts/agent/worktree.conf with the parallel-agents module.',
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
