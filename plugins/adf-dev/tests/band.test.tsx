import type { On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

// A project folder in memory: the files the mod reads, and whether the app answers.
function project(on: On, files: Record<string, string>, isUp: boolean, root = '/project'): void {
  on('session.root', async () => ({ value: root }))
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
  '/project/ops/agent/worktree.conf': "ENV_FILE=\".env\"\nREADY_URL='http://localhost:${APP_PORT}'\n",
  '/project/.env': 'APP_PORT=41180\nMAILCHIMP_API_KEY=secret\n',
}

// What the engine runs for `$.process.run`: the argument vectors the mod asked for, and Docker's answer.
function docker(on: On, stdout: string, exitCode = 0): { argv: readonly string[]; cwd?: string }[] {
  const calls: { argv: readonly string[]; cwd?: string }[] = []
  on('process.run', async ($, e) => {
    calls.push({ argv: e.argv, cwd: e.init?.cwd })
    return { value: { exitCode, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  return calls
}

const DOCKER_PICKS = {
  '/docker-picks/.claude/hooks/config.sh': "LOCAL_URL='http://localhost:${APP_PORT}'\nLOCAL_SERVICE=\"web:3000\"\n",
  '/docker-picks/.env': 'APP_PORT=\nMAILCHIMP_API_KEY=secret\n',
}

test("a worktree's URL shows above the prompt, answering", async ($, on) => {
  mock.clock(on)
  project(on, WORKTREE, true)
  const answer = await $.command.run({ command: 'local-url' })
  expect(answer).toEqual({ text: 'http://localhost:41180 is answering (from ops/agent/worktree.conf).' })
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
    text: 'No local URL. Set LOCAL_URL in .claude/hooks/config.sh (and LOCAL_SERVICE for a port Docker picks), or READY_URL in ops/agent/worktree.conf with the parallel-agents module.',
  })
  const ui = await $.ui.mount({ plugin: 'adf-dev', surface: 'terminal', ...BAND })
  expect(await ui.find({ type: 'Text', text: /engine's band/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /Local:/ })).toBeUndefined()
  await ui.unmount()
})

test('a project that has not moved the module yet: READY_URL from scripts/agent/', async ($, on) => {
  mock.clock(on)
  project(
    on,
    {
      '/legacy/scripts/agent/worktree.conf': "READY_URL='http://localhost:${APP_PORT}'\n",
      '/legacy/.env': 'APP_PORT=41280\n',
    },
    true,
    '/legacy',
  )
  const answer = await $.command.run({ command: 'local-url' })
  expect(answer).toEqual({ text: 'http://localhost:41280 is answering (from scripts/agent/worktree.conf).' })
})

test('no port pinned: the band asks Docker for the one it picked, with one fixed command', async ($, on) => {
  mock.clock(on)
  project(on, DOCKER_PICKS, true, '/docker-picks')
  const calls = docker(on, '127.0.0.1:50916\n')
  const answer = await $.command.run({ command: 'local-url' })
  expect(answer).toEqual({
    text: 'http://localhost:50916 is answering (from .claude/hooks/config.sh, port from docker compose port).',
  })
  expect(calls[0]).toEqual({ argv: ['docker', 'compose', 'port', 'web', '3000'], cwd: '/docker-picks' })
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ plugin: 'adf-dev', surface, ...BAND })
    expect((await ui.find({ type: 'Markdown' }))?.props.text).toBe('[http://localhost:50916](http://localhost:50916)')
    await ui.unmount()
  }
  // Answering, the port it found is kept: asking again runs nothing new.
  const before = calls.length
  await $.command.run({ command: 'local-url' })
  expect(calls.length).toBe(before)
})

test('a port pinned in the env file wins, and nothing runs', async ($, on) => {
  mock.clock(on)
  project(on, { ...DOCKER_PICKS, '/docker-picks/.env': 'APP_PORT=48765\n' }, true, '/docker-picks')
  const calls = docker(on, '127.0.0.1:50916\n')
  const answer = await $.command.run({ command: 'local-url' })
  expect(answer).toEqual({ text: 'http://localhost:48765 is answering (from .claude/hooks/config.sh).' })
  expect(calls).toEqual([])
})

test("the stack is down: Docker reports no port, and the band shows the engine's own", async ($, on) => {
  mock.clock(on)
  project(
    on,
    {
      '/stack-down/.claude/hooks/config.sh': DOCKER_PICKS['/docker-picks/.claude/hooks/config.sh'],
      '/stack-down/.env': 'APP_PORT=\n',
    },
    false,
    '/stack-down',
  )
  docker(on, '', 1)
  const answer = await $.command.run({ command: 'local-url' })
  expect(answer).toEqual({
    text: 'No local URL. Set LOCAL_URL in .claude/hooks/config.sh (and LOCAL_SERVICE for a port Docker picks), or READY_URL in ops/agent/worktree.conf with the parallel-agents module.',
  })
})

test('a LOCAL_SERVICE that is not a service and a port never reaches the command', async ($, on) => {
  mock.clock(on)
  project(
    on,
    {
      '/odd/.claude/hooks/config.sh': "LOCAL_URL='http://localhost:${APP_PORT}'\nLOCAL_SERVICE='web; rm -rf ~:3000'\n",
      '/odd/.env': 'APP_PORT=\n',
    },
    true,
    '/odd',
  )
  const calls = docker(on, '127.0.0.1:50916\n')
  await $.command.run({ command: 'local-url' })
  expect(calls).toEqual([])
})

test('the port it kept stops answering: the band asks Docker again, and follows the new one', async ($, on) => {
  mock.clock(on)
  let picked = '50916'
  on('session.root', async () => ({ value: '/restarted' }))
  on('fs.read', async ($, e) => {
    const files: Record<string, string> = {
      '/restarted/.claude/hooks/config.sh': DOCKER_PICKS['/docker-picks/.claude/hooks/config.sh'],
      '/restarted/.env': 'APP_PORT=\n',
    }
    const text = files[e.path]
    return text === undefined ? { deny: `no such file: ${e.path}` } : { value: text }
  })
  // Only the port Docker holds now answers.
  on('http.fetch', async ($, e) =>
    e.url === `http://localhost:${picked}`
      ? { value: { status: 200, ok: true, headers: {}, text: '' } }
      : { deny: 'connection refused' },
  )
  let lookups = 0
  on('process.run', async () => {
    lookups += 1
    return { value: { exitCode: 0, stdout: `127.0.0.1:${picked}\n`, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  expect(await $.command.run({ command: 'local-url' })).toEqual({
    text: 'http://localhost:50916 is answering (from .claude/hooks/config.sh, port from docker compose port).',
  })
  picked = '50999' // the stack restarted, and Docker picked another port
  expect(await $.command.run({ command: 'local-url' })).toEqual({
    text: 'http://localhost:50999 is answering (from .claude/hooks/config.sh, port from docker compose port).',
  })
  expect(lookups).toBe(2)
})
