# s390x Reporting Flow

This document defines how we record s390x remediation runs, logs, and status.

## Directory and File Layout

- Daily journal: `docs/s390x/zkd0-build-journal-YYYY-MM-DD.md`
- Daily logs: `docs/s390x/logs/YYYY-MM-DD/`
- Daily run index: `docs/s390x/logs/YYYY-MM-DD/RUN-INDEX.md`
- Upstream drafts: `docs/s390x-upstream-issue-pr-drafts.md`

## Log Naming Convention

Use:

`<component>-<scope>-r<run_id>-<UTC timestamp>.log`

Examples:

- `proxy-docker-tests-r68-20260222T230925Z.log`
- `s390x-integration-wide-make-mtu-r40-20260221T220735Z.log`

Rules:

- UTC timestamps only: `YYYYMMDDTHHMMSSZ`.
- `r<run_id>` is monotonically increasing per active remediation stream.
- Keep component and scope stable so logs are grep-friendly.
- Keep existing historical names as-is; use this format for all new logs.

## Run Ledger Requirements

Every run must be represented in that date's `RUN-INDEX.md` with:

- run id
- component
- command
- status (`passed`, `failed`, `in_progress`, `blocked`)
- local log path
- remote log path (if remote execution)
- one-line outcome or blocker summary

## Journal Update Requirements

Each daily journal should include:

- session metadata (`Date`, `Branch`, `Workspace`)
- key remediations applied that day
- latest completed run outcome
- current in-flight run status
- links to the daily run index and relevant upstream draft sections

## Sanitation Rules

- Use repo-relative paths in Markdown evidence links.
- Avoid user-home absolute paths in report docs.
- Keep host identity and platform details only where operationally needed.
- Do not include secrets, tokens, kubeconfigs, or private key material.

## Remote Sync Loop

When running on `zkd0`, sync logs locally on each state change:

```bash
UTC_DATE="$(date -u +%Y-%m-%d)"
mkdir -p "docs/s390x/logs/${UTC_DATE}"
rsync -az \
  "zkd0:/root/work/cilium-s390x/docs/s390x/logs/${UTC_DATE}/" \
  "docs/s390x/logs/${UTC_DATE}/"
```

Then update:

1. `docs/s390x/logs/${UTC_DATE}/RUN-INDEX.md`
2. `docs/s390x/zkd0-build-journal-${UTC_DATE}.md`

## Upstream Evidence Hygiene

Before upstreaming:

- keep issue/PR draft evidence references repo-relative
- cite the exact run log and run id
- isolate architecture scope (`s390x` only) in change rationale
- verify the proposed fix does not alter default behavior on other arches

Quick local checks:

```bash
rg -n "/Users/|/home/" docs/s390x docs/s390x-upstream-issue-pr-drafts.md
rg -n "TODO|TBD" docs/s390x/logs/$(date -u +%Y-%m-%d)/RUN-INDEX.md
```
