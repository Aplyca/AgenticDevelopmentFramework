# 0079: No file count in the lanes — the lane depends on whether there is something to decide

- **Status:** accepted
- **Date:** 2026-11-13
- **Amends:** [0011](0011-lanes-ceremony-follows-risk.md) — the fast lane's "about 3 files or fewer"
  and the full lane's "more than ~3 files" go

## Context

- **0011 said ceremony follows risk and uncertainty, not size,** and still kept a size test: about
  3 files or fewer for the fast lane, more than ~3 files as a trigger for the full lane.
- **The count sent mechanical changes to the full lane.** A rename across ten files, or a fix
  repeated in each of a feature's files, has nothing to decide, yet it got a spec, a plan, and a
  stop for the developer's approval.
- **The maintainer's call: the lane depends only on whether there is something to decide.** It is
  one of the stops an agent can do without.

## Decision

- **The fast lane has no file count.** It is a precise request (or a bug with a clear cause), in
  one layer, with no escalation trigger — however many files it touches.
- **"More than ~3 files" is no longer a trigger for the full lane.** The others stay: a requirement
  that is unclear or leaves a design choice to us, a new feature or module, a new dependency, work
  across layers.
- **The risk triggers are unchanged.** A change in a risk area or a sensitive area is careful at
  least, whatever its size.
- **The triage still states the files it expects to touch,** and a fast-lane change that touches
  more than it stated is triaged again (`/adf:triage`).

## Consequences

- **Fewer stops:** a wide mechanical change runs test-first and reaches the pull request without a
  plan to approve.
- **A large diff can start without a plan the developer saw.** The tests, `/adf:review`, CI, and
  the developer's review on the pull request still apply in every lane.
- **Judgment carries more weight at triage:** "nothing to decide" is the test, and a developer who
  says "full lane on this" is always honored.

## Alternatives considered

- **Raise the count** (ten files, say): still a size test, and any number is arbitrary.
- **Keep the count:** one approval for every change over ~3 files, mechanical or not.
