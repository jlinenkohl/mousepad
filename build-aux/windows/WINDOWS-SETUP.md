# Mousepad Windows Build Setup (Vanilla Machine)

This guide is for building Mousepad on Windows with:
- MSVC (Visual Studio Build Tools)
- Meson + Ninja
- Prebuilt GTK3/GTKSOURCEVIEW development prefix
- gettext tools for translation steps

It assumes a fresh Windows machine with only VS Code installed.

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
```

Or bootstrap first:

```powershell
./build-aux/windows/bootstrap.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
```

If gettext is not in the default winget location, pass it explicitly:

```powershell
./build-aux/windows/bootstrap.ps1 -BuildDir build-msvc -GtkPrefix Q:\gtk3 -GettextPrefix "C:\path\to\gettext-prefix"
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
