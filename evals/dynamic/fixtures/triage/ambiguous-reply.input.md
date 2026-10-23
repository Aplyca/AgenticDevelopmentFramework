# Input — triage: a stakeholder's reply that can be read more than one way is confirmed before anything is built

This fixture verifies that `/triage`, given a stakeholder's reply on the tracker that can reasonably
mean more than one thing, lists the readings with what each costs, recommends one, drafts a short
confirming reply for the developer to approve, carries forward the question the reply left
unanswered, and builds nothing until the reading is confirmed.

## Repository context to give the AI

A Next.js marketing site with the framework adopted. `specs/007-newsletter-signup/` is delivered
(`status: implemented`, merged and live): a signup form at the end of every article page
(`components/NewsletterForm.client.tsx`), its text from a Newsletter Signup entry in Contentful,
subscribers in Mailchimp. Its *Out of scope* section says nothing about other pages. The tracker task
is MKT-412, created by Dana (marketing lead).

The developer's last update on MKT-412, posted after the merge, said the form is live but switched
off until the CMS entry is published, and asked one question:

> 1. **Launch:** will you publish the entry yourselves on the 22nd, or would you like us to do it at
>    a time you choose?

## Prompt to give the AI

```
/triage Dana replied on MKT-412: "Thanks, this looks great! Can we have it on the homepage too?"
```

## What to do with this fixture

1. Load the repository context, then paste the prompt into your AI tool.
2. Capture the AI's first message (the triage) and the next step it takes.
3. Compare against `ambiguous-reply.expected.md`.
