// What the local-environment band shows: the URL, the file it came from, and whether it answered.
export type LocalEnvironment = { url: string; from: string; isUp: boolean }

declare module 'claude-code' {
  interface PluginState {
    'adf-dev': { localEnvironment: LocalEnvironment | null }
  }
}
