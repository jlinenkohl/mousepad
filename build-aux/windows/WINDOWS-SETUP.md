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
```

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

## 6. Known Current Portability Blockers

After environment fixes, current next failures are source portability items:
- MSVC does not support VLA usage in `mousepad/mousepad-history.c`
- `geteuid()` usage in `mousepad/mousepad-document.c` and `mousepad/mousepad-window.c`

These are code-level porting tasks, not environment setup issues.

## 7. Upstream Sync Workflow (Recommended)

To keep Windows changes as a thin layover:
1. Update fork `master` from upstream `master`.
2. Merge `master` into `dev/windows-gtk3`.
3. Keep Windows-only script/docs changes isolated where possible.
4. Keep core-source portability patches in small, focused commits.

This minimizes rework when upstream moves.

## 8. Notes For Future Contributors

- Prefer Windows-specific changes under `build-aux/windows/` when possible.
- Keep source portability fixes as small, focused commits to ease upstream merges.
- If you later adopt `vcpkg`, add explicit script support (toolchain/env wiring)
	so setup remains deterministic for new contributors.
