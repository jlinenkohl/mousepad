# Fork Changelog

This changelog tracks fork-specific changes on top of upstream Mousepad.
It complements upstream release notes in `NEWS`.

## 2026-03-07 - Windows/MSVC Porting Milestone

Scope: `dev/windows-gtk3` fork branch.

### Build And Tooling

- Added and hardened Windows build helpers under `build-aux/windows/` for
  configure, compile, run, runtime staging, and bootstrap checks.
- Standardized Meson handling for Windows shells:
  - Prefer `meson` on `PATH`.
  - Fallback to `C:\Program Files\Meson\meson.exe` (winget install path).
  - Fallback to `py -m mesonbuild.meson` / `python -m mesonbuild.meson`.
- Enabled default runtime staging in `2-compile.ps1` so `mousepad.exe` can run
  more reliably from plain shells.
- Added `.gitignore` in `build-aux/windows/` to keep generated
  `.gettext-overlay/` out of commits.

### Runtime And Stability (Windows)

- Improved startup resilience in menu/settings paths with null checks and
  safer action state handling.
- Added Windows-focused application behavior improvements:
  - Non-unique app mode default unless explicitly enabled.
  - Explicit resource registration for static Windows linking path.
  - Windows-friendly default editor font fallback.
- Added settings CLI operations directly in `mousepad.exe`:
  - `--get-setting`
  - `--set-setting`
  - `--reset-setting`

### Theme Loading

- Added external style scheme discovery for `themes/*.xml` and optional
  `MOUSEPAD_THEME_DIRECTORY` overrides.
- Wired theme discovery into startup before style-scheme menu population.
- Added runtime staging and launcher environment support for themes.
- Added GtkSourceView 4-compatible default theme XMLs in `themes/`.
- Added `themes/README.md` with provenance and refresh instructions.

### Documentation

- Expanded Windows docs:
  - `build-aux/windows/README.md`
  - `build-aux/windows/WINDOWS-SETUP.md`
- Added guidance for:
  - WinDbg/cdb crash debugging
  - keyfile settings backend usage
  - Meson install/version mismatch handling
  - self-contained runtime staging
  - custom theme workflow

### Notes

- Upstream release history remains in `NEWS`.
- This file is intentionally fork-oriented and should be updated for future
  fork deltas that are not yet upstreamed.