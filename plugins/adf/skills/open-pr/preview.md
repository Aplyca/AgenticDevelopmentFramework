# Check the preview

`/adf:open-pr` reads this at step 7, when the project has previews (`AGENTS.md` § Quick reference)
and the change alters something a person sees or uses.

**If possible and applicable:** a preview behind a sign-in you don't have, or a change with nothing a
person sees, is skipped — the *Preview* line and the report say which.

Wait for its deploy in the background — the host's check for it, `gh pr checks <n> --watch`, run as
a background command, never a polling loop; the same watch waits for CI (step 8). Then **test** it:
walk the same flow you checked locally, on the preview's URL, with any criterion only a shared
service could run. Then **review** what a person sees there:
- the changed page at a phone's width and a desktop's — nothing cut off, overlapping, or out of place;
- its copy — what the spec or the request says, with no placeholder or untranslated text;
- the browser console — no new errors or failed requests;
- basic accessibility — a label on each field, a visible focus as you tab, no contrast that's
  visibly off;
- anything that differs from the local run.

A finding is yours to fix on the branch before ready (step 8), walked locally first; one you can't
fix goes under *Not verified*, with why. Both, test and review:
- **Read-only.** The preview is shared and may reach real services: don't submit what reaches a
  person or shared data unless the developer asks. Use a browser, not the end-to-end suite, which
  creates data and runs only against the local stack.
- **Record it** in the body's *Preview* line (`gh pr edit <n> --body-file <file>`, from the
  current body, never from what you wrote last).
- **A difference from local** — it works here, not there — goes to the developer with what
  differs: configuration, data, the platform. It's not fixed by retrying the deploy.
- **The deploy fails:** the *Preview* line says so, naming the failing check. Don't retry it on
  your own; the report says the preview couldn't be checked, and why.

Your test and review here are part of what lets you mark the pull request ready (step 8). The
developer's review on the preview comes after it, and decides.
