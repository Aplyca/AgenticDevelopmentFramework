import { describe, expect, test } from 'claude-code/testing'

import { chooseUrl, expand, markdownLink, parsePublishedPort, parseService, parseSettings } from '../hooks/local-url'

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
      from: 'ops/agent/worktree.conf',
    })
    expect(
      chooseUrl({}, { READY_URL: 'http://localhost:${APP_PORT}' }, { APP_PORT: '41180' }, 'scripts/agent/worktree.conf'),
    ).toEqual({ url: 'http://localhost:41180', from: 'scripts/agent/worktree.conf' })
  })

  test('none: nothing declared, a port the checkout lacks, or a value that is not an http URL', () => {
    expect(chooseUrl({}, {}, {})).toBeNull()
    expect(chooseUrl({}, { READY_URL: 'http://localhost:${APP_PORT}' }, {})).toBeNull()
    expect(chooseUrl({ LOCAL_URL: 'localhost:3000' }, {}, {})).toBeNull()
    expect(chooseUrl({ LOCAL_URL: 'file:///etc/passwd' }, {}, {})).toBeNull()
  })
})

describe('parseService', () => {
  test("a Compose service and its container port, and nothing else", () => {
    expect(parseService('web:3000')).toEqual({ service: 'web', port: '3000' })
    expect(parseService('api-v2.internal_1:8080')).toEqual({ service: 'api-v2.internal_1', port: '8080' })
    for (const odd of [undefined, '', 'web', ':3000', 'web:', 'Web:3000', 'web:3000:1', 'web;rm:3000', '-p:3000', 'web:123456']) {
      expect(parseService(odd)).toBeNull()
    }
  })
})

describe('parsePublishedPort', () => {
  test("the host port docker compose port prints, or null", () => {
    expect(parsePublishedPort('127.0.0.1:50916\n')).toBe('50916')
    expect(parsePublishedPort('[::1]:50916')).toBe('50916')
    expect(parsePublishedPort('0.0.0.0:41000\n127.0.0.1:50916\n')).toBe('50916')
    for (const odd of ['', 'service "web" is not running', '127.0.0.1:0', '127.0.0.1:70000', ':']) {
      expect(parsePublishedPort(odd)).toBeNull()
    }
  })
})

describe('markdownLink', () => {
  test('links the URL, escaping what Markdown would read as syntax', () => {
    expect(markdownLink('http://127.0.0.1:47801')).toBe('[http://127.0.0.1:47801](http://127.0.0.1:47801)')
    expect(markdownLink('http://[::1]:3000')).toBe('[http://\\[::1\\]:3000](http://[::1]:3000)')
    expect(markdownLink('http://localhost:3000/a(b)c')).toBe('[http://localhost:3000/a(b)c](http://localhost:3000/a%28b%29c)')
  })
})
