# Check the preview

`/adf:open-pr` reads this at step 7, when the project has previews (`AGENTS.md` § Quick reference)
and the change alters something a person sees or uses.

Wait for its deploy in the background — the host's check for it, `gh pr checks <n> --watch`, run as
a background command, never a polling loop — then walk the same flow you checked locally, on the
preview's URL:
- **Read-only.** The preview is shared and may reach real services: don't submit what reaches a
  person or shared data unless the developer asks. Use a browser, not the end-to-end suite, which
  creates data and runs only against the local stack.
- **Record it** in the body's *Preview* line (`gh pr edit <n> --body-file <file>`, from the
  current body, never from what you wrote last).
- **A difference from local** — it works here, not there — goes to the developer with what
  differs: configuration, data, the platform. It's not fixed by retrying the deploy.
- **The deploy fails:** the *Preview* line says so, naming the failing check. Don't retry it on
  your own; the report says the preview couldn't be checked, and why.

The developer's QC on the preview still decides ready; yours is evidence for it.
