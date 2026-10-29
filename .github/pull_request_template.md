## Ticket
<!-- Jira key and link, e.g. DEM-23. Branch is cesar/<KEY>. -->

## What and why
<!-- One or two sentences: the change and the reason. -->

## How to test
<!-- Steps or commands a reviewer can run. -->

## Screenshots / recording
<!-- Required for any UI/UX change (feature or bugfix): before and after, light and dark, phone and desktop where it matters.
     Use a screen recording for motion, flows, or bugs that only show over time. Write "N/A (no UI change)" otherwise.
     Images go on a throwaway cesar/<KEY>-screenshots branch; link them as blob/<branch>/<path>?raw=true. -->

| | Before | After |
|---|---|---|
| Phone, dark |  |  |
| Phone, light |  |  |
| Desktop (if the layout changed) |  |  |

## Checklist
- [ ] `tool/check.sh` passes (there is no CI)
- [ ] Self-review done on the final diff
- [ ] Commits start with the Jira key (`DEM-n: summary`)
- [ ] CHANGELOG.md has a line under **Unreleased** for anything a user notices
- [ ] Docs updated if behavior, architecture, or data changed
- [ ] No secrets or credentials in the diff
