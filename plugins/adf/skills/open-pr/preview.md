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
- **A criterion only a shared service can run, whose walk writes:** a write that stays in a test
  sandbox — a payment provider's test mode, a CMS sandbox environment — runs, with test data. One
  that reaches a person or real shared data — a real mailing list, published content — waits for
  the developer's yes: ask once, naming the write and the test data. Until it's walked, it goes
  under *Not verified*, and the pull request stays a draft (step 8).
- **Record it** in the body's *Preview* line (`gh pr edit <n> --body-file <file>`, from the
  current body, never from what you wrote last).
- **A difference from local** — it works here, not there — goes to the developer with what
  differs: configuration, data, the platform. It's not fixed by retrying the deploy.
- **The deploy fails:** the *Preview* line says so, naming the failing check. Don't retry it on
  your own; the report says the preview couldn't be checked, and why.

Your test and review here are part of what lets you mark the pull request ready (step 8). The
developer's review on the preview comes after it, and decides.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The criteria pass on the preview, so I've reviewed it" | Walking the criteria is the test. The review looks at what a person sees: the page at a phone's width and a desktop's, its copy, the console, basic accessibility. |
| "It works locally; I'll mark it ready before the preview deploys" | When the project has previews, the preview is part of your test: the production build, on the platform, with its configuration. Ready waits for its walk and for CI. |
| "I'll check it on the preview instead of starting the local stack" | Local first: the preview costs a deploy round-trip, is shared, and may reach real services. Check locally, then confirm on the preview. |
| "I'll report the draft now and send the preview when it deploys" | Two reports split the developer's test in two. The deploy and CI wait in the background, so waiting costs them nothing: report once, with both URLs and the pull request's state. |
