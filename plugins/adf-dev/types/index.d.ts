// What the local-environment band shows: the URL, where it came from (the file, and the port lookup
// when Docker picked it), and whether it answered.
export type LocalEnvironment = { url: string; from: string; isUp: boolean }

declare module 'claude-code' {
  interface PluginState {
    'adf-dev': { localEnvironment: LocalEnvironment | null }
  }
}
