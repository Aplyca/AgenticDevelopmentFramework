# The review update's template

`/adf:stakeholder-update` reads this at step 1 for the **in review** moment, and fills it in by
its style rules. It's the business side of the handoff: what changes for the people who use the
system, and what they can try. How it was built, tested, and should be reviewed is in the pull
request, for the developer.

```markdown
Hi <names>,

<Topic> is ready for you to try. <What changes for visitors or users, in one or two sentences.>

You can try it on the [preview](<the stable preview address, when there is one>):

1. <Where to go and what to do, in their terms> — <what they should see>.
2. <…>

<What isn't in it yet, or what to ignore on the preview — only when it matters.>

<What happens next, in the project's status words — e.g. the team is reviewing it; once you're happy
with it, it goes live with the next release.>

For reference, the change is in this [pull request](<link>).

Thanks!
```

- **With no preview,** say where they'll see it once it's live, and leave the steps out.
- **Requesters can't open pull requests** (`docs/TRACKER-INTEGRATION.md` § Stakeholder updates):
  word the last line for the team — "For the team's reference: <link>".
- **Questions for the requester** aren't part of this update: it posts on its own. They're a second
  message, a draft for the developer's yes:

  ```markdown
  Hi <names>,

  <N> questions on <topic>:

  1. **<Topic>:** <direct question, with the options and links>?

  Thanks!
  ```
