# Mentions, links, and images in a posted update

`/adf:stakeholder-update` reads this at step 6 when the comment mentions someone, links another task
or comment, or carries an image. What each needs depends on the tracker's tools:
`docs/TRACKER-INTEGRATION.md` § Stakeholder updates says what this tracker's carry.

- **Mentions:** mention people with the tracker's mention syntax (§ Stakeholder updates); a bare
  `@Name` may notify no one. Where the tracker moves mentions, greet by name in plain text and put
  the mentions where it places them.
- **Links to other tasks or comments** go out as plain links when the tools can't make the
  tracker's preview (§ Stakeholder updates): ask the developer to paste each one that should show
  as a preview in the tracker's editor, and read the comment again once they have.
- **Images:** as `<this skill's base directory>/screenshots.md` § Posting them says — in a draft
  the developer approved, they paste each one over its placeholder.
