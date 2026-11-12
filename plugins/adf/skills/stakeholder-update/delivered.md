# The delivered update's template

`/adf:stakeholder-update` reads this at step 1 for the **delivered** moment — the change is live
(`SKILL.md` § Live), or the answer is given — and fills it in by its style rules.

```markdown
Hi <names>,

<Topic> is live. <Why it wasn't working, or what was needed, in one or two sentences.> To fix it, we
<what we did, with links>. <What visitors or users get now, with the live page.>

<How to use it: the [usage guide](<link>) — only when the task has one.>

We noticed a few things along the way:

- **<Finding>** <one sentence, with a link — and whether we're handling it>.

Thanks!
```

- **An answer-only task:** the update is the answer, in the client's terms; drop "is live" and what
  doesn't apply. It's a draft, posted on the developer's yes.
- **Asked for before it's live:** say what's live and what's pending, in the project's status words,
  and leave the task's status where it is.
- **Questions for the requester** aren't part of this update: it posts on its own. They're a second
  message, a draft for the developer's yes, as in `review.md`.
