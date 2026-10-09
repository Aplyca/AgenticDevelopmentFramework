import { describe, expect, test } from 'claude-code/testing'

import { chooseUrl, expand, parseSettings } from '../hooks/local-url'

describe('parseSettings', () => {
  test('reads quoted, single-quoted, and bare values, ignoring comments and other keys', () => {
    const text = [
      '# a comment',
      'LOCAL_URL="http://localhost:3000"   # CUSTOMIZE',
      "  READY_URL='http://localhost:${APP_PORT}'",
      'APP_PORT=41180 # reserved by worktree-new.sh',
      'SECRET_TOKEN=abc123',
    ].join('\n')
    expect(parseSettings(text, ['LOCAL_URL', 'READY_URL', 'APP_PORT'])).toEqual({
      LOCAL_URL: 'http://localhost:3000',
      READY_URL: 'http://localhost:${APP_PORT}',
      APP_PORT: '41180',
    })
  })
})

describe('expand', () => {
  test('fills ${APP_PORT}, and gives null when the value is missing', () => {
    expect(expand('http://localhost:${APP_PORT}', { APP_PORT: '41180' })).toBe('http://localhost:41180')
    expect(expand('http://localhost:${APP_PORT}', {})).toBeNull()
    expect(expand('http://localhost:3000', {})).toBe('http://localhost:3000')
  })
})

describe('chooseUrl', () => {
  test("the project's LOCAL_URL wins over the worktree's READY_URL", () => {
    expect(
      chooseUrl({ LOCAL_URL: 'http://localhost:3000' }, { READY_URL: 'http://localhost:${APP_PORT}' }, { APP_PORT: '41180' }),
    ).toEqual({ url: 'http://localhost:3000', from: '.claude/hooks/config.sh' })
  })

  test("a worktree's READY_URL with its own port", () => {
    expect(chooseUrl({}, { READY_URL: 'http://localhost:${APP_PORT}' }, { APP_PORT: '41180' })).toEqual({
      url: 'http://localhost:41180',
      from: 'scripts/agent/worktree.conf',
    })
  })

  test('none: nothing declared, a port the checkout lacks, or a value that is not an http URL', () => {
    expect(chooseUrl({}, {}, {})).toBeNull()
    expect(chooseUrl({}, { READY_URL: 'http://localhost:${APP_PORT}' }, {})).toBeNull()
    expect(chooseUrl({ LOCAL_URL: 'localhost:3000' }, {}, {})).toBeNull()
    expect(chooseUrl({ LOCAL_URL: 'file:///etc/passwd' }, {}, {})).toBeNull()
  })
})
