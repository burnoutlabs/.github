# scripts

Org housekeeping scripts. Both need an authenticated `gh` with admin rights on
the burnoutlabs repositories. Both are dry runs by default: they read the
current state and print the `gh` commands they would run. Add `--apply` to run
them. Both are idempotent, so a second run after `--apply` plans nothing.

| Script | What it does |
| --- | --- |
| `sync-labels.sh [--apply] [repo ...]` | Applies the shared label set (`type:*`, `area:*`) to every non-archived repo: creates missing labels, fixes colours and descriptions, deletes GitHub's default labels that no issue or PR uses, and reports the rest. |
| `repo-metadata.sh [--apply]` | Sets the description and adds topics (`rocketry`, `high-power-rocketry` plus area topics) on each public repo. Never removes a topic. |

Archived repositories cannot be edited, so run both before archiving anything.

The scripts change existing repositories only. To make new repositories start
with the shared labels, also set them as the organisation's default repository
labels (Settings, Repository defaults).

## Tests

```sh
scripts/tests/run.sh
```

runs both scripts against a stub `gh` (`tests/stub/gh`) that serves a fixture
and logs every call, so it needs no network or GitHub access. It needs `bash`
and `python3`.
