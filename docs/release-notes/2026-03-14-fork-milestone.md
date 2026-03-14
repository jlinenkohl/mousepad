# Fork Milestone Notes (2026-03-14)

## 1) GitHub PR Body (Checklist-Friendly)

## Summary

This branch continues the Windows/MSVC portability effort and layers two major feature tracks on top:

- rectangular column/block editing
- external GtkSourceView language spec loading

Version marker was bumped to `0.7.1-dev` for this fork milestone.

## Scope

- Windows build/run/staging hardening (`build-aux/windows/*`)
- Column mode editing (`feat/blockmode`)
- External language-spec discovery/staging (`feat/syntax-highlighting`)
- Fork changelog/summary updates and milestone version bump

## What Changed

### Column mode (`feat/blockmode`)

- Added rectangular selection/edit mode with status sync (`COL`/`LNR`).
- Implemented rectangular copy/cut/paste/delete.
- Added thin-column insertion workflows.
- Improved mouse and keyboard rectangle selection handling/alignment.
- Added block-aware `Tab` / `Shift+Tab` behavior.
- Hardened undo/redo interaction for column operations.

### Syntax highlighting / language specs (`feat/syntax-highlighting`)

- Added external language-spec loading for GtkSourceView (`*.lang`, `*.xml`).
- Added support for required schema file (`language2.rng`) in staged runtime.
- Added env override:
  - `MOUSEPAD_LANGUAGE_SPEC_DIRECTORY`
- Added settings override:
  - `preferences.view.language-specs-directory`
- Added repo-local `language-specs/` and Windows runtime staging support.

### Docs / Metadata

- Added milestone summary to `CHANGELOG.md`.
- Bumped dev version to `0.7.1-dev`.
- Expanded Windows docs for theme/language-spec staging and runtime behavior.

## Compatibility / Non-Goals

- No GTK4 / GtkSourceView5 migration in this branch.
- Upstream alignment remains GTK3 + GtkSourceView4 for now.

## Testing Notes

- Built and linked successfully in Windows MSVC workflow.
- Runtime staging validated via `build-aux/windows/2-compile.ps1`.
- Manual verification done for:
  - column-mode editing paths,
  - selection/overlay alignment,
  - external language-spec discovery.

## Follow-ups

- Line-ending preservation policy for mixed-EOL files is documented as a deferred follow-up (no behavior change yet).

## Checklist

- [x] Build succeeds (Windows/MSVC path)
- [x] Feature flags/settings wired
- [x] Runtime staging updated
- [x] Docs updated
- [x] Branch pushed

## 2) NEWS-Style Entry (Upstream Tone)

0.7.1 (Unreleased, fork milestone)
=====
- Add rectangular (column) editing mode with improved selection behavior.
- Implement block-aware tab and reverse-tab operations for column workflows.
- Improve column-mode undo/redo interaction stability.
- Add external GtkSourceView language specification loading support.
- Add environment and settings-based search path support for language specs.
- Stage external language specs and schema for Windows runtime runs.
- Update Windows documentation for runtime staging and configuration.
- Update fork changelog with milestone summary.

Notes:
- GTK stack remains GTK3 + GtkSourceView4 in this phase.
- Line-ending preservation policy enhancements are deferred for follow-up.

## 3) User/Maintainer Split

## What Changed For Users

- New column/block editing behavior is available and significantly improved.
- `Tab`/`Shift+Tab` now behave in a more editor-expected way during block edits.
- Syntax language definitions can be extended externally via `language-specs/`.
- Better Windows runtime behavior when launching from staged builds.

## What Changed For Maintainers

- Clear branch stack:
  1. `dev/windows-gtk3`
  2. `feat/blockmode`
  3. `feat/syntax-highlighting`
- Added configurable external language-spec path:
  - setting: `preferences.view.language-specs-directory`
  - env: `MOUSEPAD_LANGUAGE_SPEC_DIRECTORY`
- Added Windows staging support for language specs (`.lang`, `.xml`, `language2.rng`).
- Milestone documented in `CHANGELOG.md`.
- Dev version bumped to `0.7.1-dev`.
- GTK4/GtkSourceView5 migration intentionally deferred to avoid upstream divergence.
