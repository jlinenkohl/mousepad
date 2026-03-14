# Copilot Working Context: Mousepad Fork Maintenance Policy

## Primary Objective
Keep this fork as close as possible to upstream Mousepad while extending support and features in a way that remains upstream-friendly.

## Guiding Principles
- Upstream-first: prefer fixes/implementations that can work on Linux/Xfce GTK builds too, not Windows-only behavior.
- Least disruptive: avoid broad re-architecture of core Mousepad code paths when a localized change is sufficient.
- Isolate intent: each change should be clearly classifiable as one of:
	- `bugfix:` existing bug fix (upstream candidate)
	- `feat:` new feature (upstream candidate if generic)
	- `windows-only:` Windows/MSVC/runtime glue only
- Keep platform glue contained to `build-aux/windows/*` and narrow `#ifdef G_OS_WIN32` sections.

## Branch + Commit Strategy
- Use short-lived topic branches from `dev/windows-gtk3`:
	- `bugfix/<topic>`
	- `feat/<topic>`
	- `windows/<topic>`
- Keep commits single-purpose and small.
- Prefer commit subjects with explicit taxonomy prefix:
	- `bugfix: ...`
	- `feat: ...`
	- `windows-only: ...`
- Do not mix unrelated categories in one commit.

## Reviewability Rules
- Every patch should answer:
	1. Is this upstream-candidate or Windows-only?
	2. What files carry the change and why those files only?
	3. What regression risk exists for upstream Linux/Xfce behavior?
- For nontrivial behavior changes, keep logic behind explicit mode/setting flags.

## Rebase / Upstream Sync Hygiene
- Regularly rebase `dev/windows-gtk3` onto upstream/master equivalent.
- Keep Windows-only commits grouped and easy to drop/cherry-pick.
- Avoid formatting-only churn in functional commits.

## Current Practical Notes
- Windows startup may emit DBus helper warnings when session DBus binaries are absent; avoid introducing hard DBus dependencies.
- Runtime/plugin path issues and staged DLL behavior belong in `build-aux/windows/*` and should not leak into generic app logic unless necessary.

## Follow-up Notes
- Line ending behavior needs follow-up discussion with user before implementation changes.
- Current behavior summary (verified in code):
	- On open, EOL is inferred from the first line ending encountered (`LF`/`CR`/`CRLF`).
	- On save, output is normalized to the document's current selected line ending mode.
	- There is no explicit "preserve existing/mixed line endings exactly" mode today.
- Risk called out by user: opening mixed-ending files can lead to unintended normalization on save.
- Follow-up task: design a preserve-existing policy (including mixed-EOL strategy) that is upstream-friendly and opt-in/out via clear settings/UI.

## Working Repository
- Canonical repo path: `Q:\projects\mousepad`
- Active integration branch: `dev/windows-gtk3`
