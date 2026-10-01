# Glossary

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: the project's domain language -->

The project's own words: one term per concept, used the same way in conversations, specs, code,
tests, and docs. A shared vocabulary keeps names consistent across the codebase and makes requests,
specs, and agent output shorter and less ambiguous.

---

## How to use this glossary

- **One term per concept.** When several words exist for the same thing, pick the best one and list
  the others under *Avoid*.
- **Use the terms exactly** — in specs, code identifiers, test names, docs, and user-facing text.
- **Define what it is, in one or two sentences.** No implementation details — table names, file
  paths, and how it's built belong in `docs/reference/`.
- **Only this project's concepts.** General programming terms (timeout, cache, retry) don't belong,
  however often the code uses them.
- **Challenge mismatches.** When a request uses an *Avoid* word, or one word for two concepts, say
  which term is meant before writing anything down.
- **Add a term the moment it's settled** — in the same change as the spec or code that introduces it.
- Group related terms under a heading once natural clusters appear; otherwise keep the list
  alphabetical.

---

<!--
Copy this block for each new term:

## [Term]

[What it is, in one or two sentences.]
**Avoid:** [other words people use for it, and why each is wrong here]
**Example:** [the term in a sentence from this project]

-->

## [Example term: Subscriber]

A reader whose email address is on the newsletter list.
**Avoid:** *member* (members have paid accounts), *contact*, *user* (a user has a login; a
subscriber needn't)
**Example:** "A reader becomes a subscriber when their signup is accepted."

## [Example term: Signup]

One submission of the newsletter form — whether or not it creates a subscriber.
**Avoid:** *registration* (that creates an account), *subscription* (the ongoing state, not the
event)
**Example:** "Ten signups per minute from one network address are allowed."
