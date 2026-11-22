# Screenshots in a stakeholder update

`/adf:stakeholder-update` reads this at step 4, when a picture shows the client something words
can't, such as the fix working.

## Taking them

Take them from the preview or the live site, **read-only**: submit no form, change no setting, edit
no content. With Playwright (the `e2e` module, or a browser tool the session has):

- Use a desktop viewport, such as 1440×900, and `deviceScaleFactor: 2`, so text stays sharp
  when the tracker scales the image down.
- Wait for the data the shot depends on: the element with its content, not only the page load.
- Hide consent banners by injecting CSS after load, such as
  `page.addStyleTag({ content: '<banner selector> { display: none !important; }' })`. **Never
  accept or decline cookies** — either one records a consent choice on the site.
- Screenshot the element the sentence points at (`locator.screenshot()`), not the full page.
- Save each file outside the repository, named for what it shows.

Show each image to the developer before it's used, and drop one that shows what it shouldn't:
personal data, a draft entry, an error.

## Posting them

An update that posts on its own carries no placeholder: hand the files to the developer in your
report, to add in the tracker if they want them. The rest is for a draft the developer approved.

When the tracker's comment tool can't show an image inline, post the text with each
`[Screenshot N: <what it shows>]` line in place, and ask the developer to paste each image over its
placeholder in the tracker. Never upload the images to the task to "embed" them: an attachment lands
on the task, away from the sentence it illustrates. Once the developer has pasted them, read the
comment again where the tracker shows a pasted image in its text (`docs/TRACKER-INTEGRATION.md`
§ Stakeholder updates), to confirm each one replaced its placeholder.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll upload the screenshots to the task so they're embedded" | An attachment lands on the task, not in the comment. Hand the files over; the developer pastes each over its placeholder. |
| "I'll accept the cookie banner to get it out of the shot" | That records a consent choice on the site. Hide the banner with CSS after load. |

## Red flags (stop and reassess)

- A screenshot the developer hasn't seen, or one taken by clicking through a consent banner.
