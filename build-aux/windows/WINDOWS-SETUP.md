# Mousepad Windows Build Setup (Vanilla Machine)

This guide is for building Mousepad on Windows with:
- MSVC (Visual Studio Build Tools)
- Meson + Ninja
- Prebuilt GTK3/GTKSOURCEVIEW development prefix
- gettext tools for translation steps

It assumes a fresh Windows machine with only VS Code installed.

## vcpkg Status (Current)

`vcpkg` is currently not used by this repository's Windows build flow.

- The build scripts rely on Meson + `pkg-config` and a prebuilt GTK prefix.
- No `vcpkg` toolchain or manifest integration is wired into the current scripts.
- Installing `vcpkg` is fine, but it is optional for this specific setup unless you
	decide to rework dependency management around it.

## 1. Install Required Tools

Run these in an elevated PowerShell terminal:

```powershell
winget install --id Git.Git --exact --accept-package-agreements --accept-source-agreements
winget install --id Python.Python.3.12 --exact --accept-package-agreements --accept-source-agreements
winget install --id mesonbuild.meson --exact --accept-package-agreements --accept-source-agreements
winget install --id Ninja-build.Ninja --exact --accept-package-agreements --accept-source-agreements
winget install --id bloodrock.pkg-config-lite --exact --accept-package-agreements --accept-source-agreements
winget install --id mlocati.GetText --exact --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.WinDbg --exact --accept-package-agreements --accept-source-agreements
```

Install WinDbg to capture crash stacks (for example, startup faults that return
codes like `0xC0000005`) directly on contributor machines.

If `cdb.exe` is not on PATH after installing `Microsoft.WinDbg`, install
Debugging Tools for Windows as part of Windows SDK, or run `cdb.exe` via a
full path from the Windows Kits debugger directory.

Install MSVC Build Tools (C/C++ workload):

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --override "--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

## 2. Install/Prepare GTK Prefix

You need a prebuilt GTK prefix containing development headers and pkg-config files, including:
- `gtk+-3.0`
- `glib-2.0`
- `gio-2.0`
- `gmodule-2.0`
- `gtksourceview-4` (preferred) or `gtksourceview-3.0`

Example prefix path used below:
- `Q:\gtk3`

Expected layout example:
- `Q:\gtk3\bin`
- `Q:\gtk3\include`
- `Q:\gtk3\lib\pkgconfig`
- `Q:\gtk3\share\pkgconfig`

Recommended sources for GTK binaries and dependency context:
- gvsbuild release zips (GTK3/GTK4 prebuilt libraries):
	`https://github.com/wingtk/gvsbuild/releases/tag/2026.2.0`
- Additional GTK dependency build notes/files (MSVC):
	`https://github.com/fanc999/gtk-deps-msvc/tree/main`
- gvsbuild project (build GTK stack from source):
	`https://github.com/wingtk/gvsbuild?tab=readme-ov-file`
- MSYS2 reference (commonly needed when building stack from source):
	`https://www.msys2.org/`
- GNOME Win32/MSVC GTK stack errata and references:
	`https://wiki.gnome.org/Projects/GTK/Win32/MSVCCompilationOfGTKStack`

## 3. Clone and Open Repo

```powershell
Set-Location Q:\projects
git clone https://github.com/jlinenkohl/mousepad
Set-Location Q:\projects\mousepad
git checkout dev/windows-gtk3
```

## 4. Build (Recommended Path)

Use the provided Windows scripts. They now handle gettext/AppStream XML rule setup automatically.

```powershell
./build-aux/windows/1-configure-no-xfce-prebuilt.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
./build-aux/windows/3-run.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3
```

Or bootstrap first:

```powershell
./build-aux/windows/bootstrap.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
./build-aux/windows/3-run.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3
```

If gettext is not in the default winget location, pass it explicitly:

```powershell
./build-aux/windows/bootstrap.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3 -GettextPrefix "C:\path\to\gettext-prefix"
```

If launching `mousepad.exe` directly returns `-1073741515` (`0xC0000135`),
Windows cannot find one or more runtime DLLs. Use `3-run.ps1` so the GTK
runtime path and development schema cache are prepared automatically.
The launcher also sets `MOUSEPAD_PLUGIN_DIRECTORY` to `<builddir>/plugins`
when present, avoiding hardcoded install-prefix plugin paths during dev runs.
If `<builddir>/themes` (or repo `themes`) exists, it also sets
`MOUSEPAD_THEME_DIRECTORY` so external style XML files are discovered.

`2-compile.ps1` now stages app-local runtime DLLs into `<builddir>/mousepad`
by default, so direct `mousepad.exe` launches are self-contained.

For manual restaging (usually not needed), run:

```powershell
./build-aux/windows/4-stage-runtime.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3
```

For a smaller self-contained runtime set, stage only recursive PE dependencies
(`mousepad.exe` plus deps-of-deps) from GTK/gettext bins:

```powershell
./build-aux/windows/4-stage-runtime.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3 -MinimalDlls
```

Then run:

```powershell
./build-msvc/mousepad/run-mousepad.cmd
```

When `themes/*.xml` exists at repo root, `4-stage-runtime.ps1` copies them to
`<builddir>/themes` automatically.

`2-compile.ps1` generates `<builddir>/runtime-schemas` automatically, and the
Windows runtime path now falls back to that directory for GSettings schema
discovery during non-installed development runs.

To create a small portable release zip (self-contained, user-run, no admin):

```powershell
./build-aux/windows/5-create-release-package.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3
```

By default this uses minimal recursive DLL staging (deps-of-deps). Use
`-AllDlls` for a broader copy-all runtime package.
By default, the zip tag is auto-derived from the built binary `--version`
output (same `VERSION_FULL` shown in Help -> About, for example
`0.7.1-dev-b7042b77`). Use `-Version vX.Y.Z-<commit>` to override.
The packager also writes `dist/SHA256SUMS.txt` and `<zip>.sha256`.

Optional GitHub release publishing (requires `gh auth login`):

```powershell
./build-aux/windows/6-publish-github-release.ps1 -Tag v0.7.1-dev-b7042b77 -Version 0.7.1-dev-b7042b77
```

## 5. Quick Environment Verification

Run before configure if troubleshooting:

```powershell
cl /?
meson --version
ninja --version
pkg-config --version
msgfmt --version
pkg-config --modversion gtk+-3.0 glib-2.0 gio-2.0 gmodule-2.0 gtksourceview-4
```

Debugger install check:

```powershell
winget list --id Microsoft.WinDbg
```

Debugger command checks:

```powershell
Get-Command windbgx -ErrorAction SilentlyContinue
Get-Command cdb -ErrorAction SilentlyContinue
```

## 6. Crash Debugging (WinDbg/cdb)

For hard crashes (for example `0xC0000005`), run Mousepad under `cdb` and save
the debugger transcript:

```powershell
$cdb = @(
	'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe',
	'C:\Program Files\Windows Kits\10\Debuggers\x64\cdb.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $cdb) {
	$cdb = (Get-Command cdb -ErrorAction SilentlyContinue).Source
}

if (-not $cdb) {
	throw 'cdb.exe not found. Install Debugging Tools for Windows (SDK) or add cdb to PATH.'
}

& $cdb -o -G -g -logo build-msvc\mousepad\cdb.log -- build-msvc\mousepad\mousepad.exe --disable-server
```

The log file `build-msvc/mousepad/cdb.log` will include the exception and stack.

## 7. Runtime Notes (Fonts)

A warning like this is non-fatal on Windows:

`couldn't load font "Adwaita Mono 11", falling back to "Sans 11"`

This comes from desktop font defaults not present on a given machine. You can
ignore it, or set a Windows-available monospace font in Mousepad preferences
(for example `Consolas 10`).

## 8. Settings Backend on Windows

This Windows build flow enables `-Dkeyfile-settings=true`, so Mousepad stores
settings in a local keyfile instead of relying on desktop dconf/gsettings
services.

Default settings path:

- `%APPDATA%\Mousepad\settings.conf`

Use the built-in settings CLI to read/write values:

```powershell
./build-msvc/mousepad/mousepad.exe --get-setting preferences.window.menubar-visible
./build-msvc/mousepad/mousepad.exe --set-setting preferences.window.menubar-visible=true
./build-msvc/mousepad/mousepad.exe --reset-setting preferences.window.menubar-visible
```

`--set-setting` expects `SETTING=VALUE`.
For booleans, accepted values are `true/false`, `yes/no`, and `1/0`.

These commands work directly with the staged executable produced by
`./build-aux/windows/2-compile.ps1`.

## 9. Custom Color Schemes (themes/*.xml)

Mousepad auto-loads GtkSourceView style schemes from any `*.xml` files found
in theme directories. For this repo workflow, use:

- `themes` (repo root)
- `<builddir>/themes` (staged output)

Add or remove XML files in `themes/` without code changes, then rebuild:

```powershell
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
```

You can also point to custom directories with `MOUSEPAD_THEME_DIRECTORY`
(supports multiple paths separated by the platform path separator).

## 10. Known Current Portability Blockers

After environment fixes, current next failures are source portability items:
- MSVC does not support VLA usage in `mousepad/mousepad-history.c`
- `geteuid()` usage in `mousepad/mousepad-document.c` and `mousepad/mousepad-window.c`

These are code-level porting tasks, not environment setup issues.

## 11. Upstream Sync Workflow (Recommended)

To keep Windows changes as a thin layover:
1. Update fork `master` from upstream `master`.
2. Merge `master` into `dev/windows-gtk3`.
3. Keep Windows-only script/docs changes isolated where possible.
4. Keep core-source portability patches in small, focused commits.

This minimizes rework when upstream moves.

## 12. Notes For Future Contributors

- Prefer Windows-specific changes under `build-aux/windows/` when possible.
- Keep source portability fixes as small, focused commits to ease upstream merges.
- If you later adopt `vcpkg`, add explicit script support (toolchain/env wiring)
	so setup remains deterministic for new contributors.
