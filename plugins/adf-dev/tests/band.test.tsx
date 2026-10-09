import type { On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

// A project folder in memory: the files the mod reads, and whether the app answers.
function project(on: On, files: Record<string, string>, isUp: boolean): void {
  on('session.root', async () => ({ value: '/project' }))
  on('fs.read', async ($, e) => {
    const text = files[e.path]
    return text === undefined ? { deny: `no such file: ${e.path}` } : { value: text }
  })
  on('http.fetch', async () =>
    isUp ? { value: { status: 200, ok: true, headers: {}, text: '' } } : { deny: 'connection refused' },
  )
}

const BAND = {
  component: 'AbovePrompt',
  props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 100, scroll: { offset: 0, bodyRows: 10 }, view: {} },
} as const

const WORKTREE = {
  '/project/scripts/agent/worktree.conf': "ENV_FILE=\".env\"\nREADY_URL='http://localhost:${APP_PORT}'\n",
  '/project/.env': 'APP_PORT=41180\nMAILCHIMP_API_KEY=secret\n',
}

test("a worktree's URL shows above the prompt, answering", async ($, on) => {
  mock.clock(on)
  project(on, WORKTREE, true)
  const answer = await $.command.run({ command: 'local-url' })
  expect(answer).toEqual({ text: 'http://localhost:41180 is answering (from scripts/agent/worktree.conf).' })
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ plugin: 'adf-dev', surface, ...BAND })
    expect(await ui.find({ type: 'Text', text: /Local:/ })).toBeDefined()
    // A Markdown link, which the desktop app opens for http: too
    expect((await ui.find({ type: 'Markdown' }))?.props.text).toBe('[http://localhost:41180](http://localhost:41180)')
    expect(await ui.find({ type: 'Text', text: /not answering/ })).toBeUndefined()
    await ui.unmount()
  }
})

test("the project's LOCAL_URL, not answering", async ($, on) => {
  mock.clock(on)
  project(on, { '/project/.claude/hooks/config.sh': 'LOCAL_URL="http://localhost:3000"\n' }, false)
  const answer = await $.command.run({ command: 'local-url' })
  expect(answer).toEqual({ text: 'http://localhost:3000 is not answering (from .claude/hooks/config.sh).' })
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ plugin: 'adf-dev', surface, ...BAND })
    expect(await ui.find({ type: 'Text', text: /not answering/ })).toBeDefined()
    await ui.unmount()
  }
})

test("nothing declared: the band is the engine's own, and the command says where to declare it", async ($, on) => {
  mock.clock(on)
  project(on, {}, false)
  // What the engine draws beneath the plugin, so the test sees the mod pass the band through.
  on('ui.render', { component: 'AbovePrompt' }, async ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine's band</Text>
  })
  const answer = await $.command.run({ command: 'local-url' })
  expect(answer).toEqual({
    text: 'No local URL. Set LOCAL_URL in .claude/hooks/config.sh, or READY_URL in scripts/agent/worktree.conf with the parallel-agents module.',
  })
  const ui = await $.ui.mount({ plugin: 'adf-dev', surface: 'terminal', ...BAND })
  expect(await ui.find({ type: 'Text', text: /engine's band/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /Local:/ })).toBeUndefined()
  await ui.unmount()
})
