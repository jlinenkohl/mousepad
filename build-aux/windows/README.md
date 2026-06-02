# Windows (GTK) quick experiment (MSVC first)

This directory is a fast-start path for building Mousepad for Windows while removing XFCE-specific runtime dependencies.

For a complete step-by-step setup on a vanilla Windows machine, see:

- `build-aux/windows/WINDOWS-SETUP.md`

## What this config disables

- `shortcuts-plugin` (depends on `libxfce4ui` / `libxfce4kbd-private`)
- `gspell-plugin` (optional)
- `polkit`
- `test-plugin`

It also enables keyfile-backed settings:

- `-Dkeyfile-settings=true`

## Preferred toolchain: MSVC

Open a Visual Studio Developer Command Prompt so `cl`, `lib`, and `rc` are in PATH.

You also need:

- GTK3 development libraries for Windows
- GtkSourceView development libraries for Windows
- `pkg-config` or `pkgconf` (with `.pc` files for the above libs)
- GNU gettext tools with XML ITS data (for appdata translation merge)
- WinDbg (recommended for runtime crash diagnostics)

Install WinDbg:

```powershell
winget install --id Microsoft.WinDbg --exact --accept-package-agreements --accept-source-agreements
```

Debugger command checks:

```powershell
Get-Command windbgx -ErrorAction SilentlyContinue
Get-Command cdb -ErrorAction SilentlyContinue
```

## Fast path (MSVC)

Recommended one-shot bootstrap (checks toolchain and pkg-config deps, then configures):

```powershell
./build-aux/windows/bootstrap.ps1 -BuildDir build-msvc
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
```

## Meson on Windows

Recommended (standard) install path for this repo is `winget`:

```powershell
winget install --id mesonbuild.meson --exact --accept-package-agreements --accept-source-agreements
```

If you see a Meson version mismatch such as:

`Build directory has been generated with Meson version X, which is incompatible with the current version Y`

your build directory was configured with a different Meson version. Reconfigure
or recreate the build dir with your current Meson version:

```powershell
meson setup --reconfigure build-msvc
# or, if needed:
Remove-Item -Recurse -Force build-msvc
./build-aux/windows/1-configure-no-xfce-prebuilt.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk
```

From repo root:

```sh
build-aux/windows/1-configure-no-xfce
build-aux/windows/2-compile build-msvc
```

From Developer PowerShell:

```powershell
./build-aux/windows/1-configure-no-xfce.ps1
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
./build-aux/windows/3-run.ps1 -BuildDir build-msvc
```

`2-compile.ps1` also generates a local schema cache in
`<builddir>/runtime-schemas` for development execution on Windows.
By default it also stages app-local runtime DLLs into
`<builddir>/mousepad`, so `mousepad.exe` can be launched directly from a plain
shell.

The native file used is:

- `build-aux/windows/msvc-gtk.native.ini`

## Using a prebuilt GTK prefix

If you already have prebuilt libraries in a single prefix (for example `C:/gtk`), run:

```sh
build-aux/windows/1-configure-no-xfce-prebuilt build-msvc C:/gtk
build-aux/windows/2-compile build-msvc
```

PowerShell equivalent:

```powershell
./build-aux/windows/1-configure-no-xfce-prebuilt.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
```

Bootstrap with prebuilt prefix:

```powershell
./build-aux/windows/bootstrap.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
```

If gettext tools are installed outside your GTK prefix (for example via
`winget install mlocati.GetText`), pass `-GettextPrefix`:

```powershell
./build-aux/windows/bootstrap.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk -GettextPrefix "$env:LOCALAPPDATA/Programs/gettext-iconv"
./build-aux/windows/1-configure-no-xfce-prebuilt.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk -GettextPrefix "$env:LOCALAPPDATA/Programs/gettext-iconv"
```

The scripts create a local gettext overlay at `build-aux/windows/.gettext-overlay`
to provide AppStream locating rules required by `msgfmt` for
`*.appdata.xml.in` files.

For runtime from a non-developer shell, use:

```powershell
./build-aux/windows/3-run.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk
```

The run helper prepares `PATH` for GTK runtime DLLs and compiles/uses a local
GSettings schema cache for non-installed development runs.
It also sets `MOUSEPAD_PLUGIN_DIRECTORY` to `<builddir>/plugins` when present,
so plugin discovery is relative to the build output during development runs.
If `<builddir>/themes` exists, it also sets `MOUSEPAD_THEME_DIRECTORY` so
repo-local style scheme XML files are discovered.
If `<builddir>/language-specs` exists, it also sets
`MOUSEPAD_LANGUAGE_SPEC_DIRECTORY` so repo-local GtkSourceView language XML
files are discovered.

To restage runtime files manually (usually not needed because `2-compile.ps1`
already does this), run:

```powershell
./build-aux/windows/4-stage-runtime.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk
```

For leaner release packaging, stage only recursive PE dependencies
(`mousepad.exe` plus deps-of-deps) from GTK/gettext bins:

```powershell
./build-aux/windows/4-stage-runtime.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk -MinimalDlls
```

This creates `build-msvc/mousepad/run-mousepad.cmd` for self-contained launch.
When `themes/*.xml` exists in the repository root, they are also staged to
`<builddir>/themes` automatically.
When `language-specs/*.{lang,xml}` exists in the repository root, they are
also staged to `<builddir>/language-specs` automatically.

That helper exports:

- `PKG_CONFIG_PATH=<prefix>/lib/pkgconfig:<prefix>/share/pkgconfig`
- `PATH=<prefix>/bin:...`

## Create Portable Release Zip

To create a small self-contained release zip for Windows 11:

```powershell
./build-aux/windows/5-create-release-package.ps1 -BuildDir build-msvc -GtkPrefix C:/gtk
```

By default, this uses minimal recursive DLL staging (deps-of-deps closure).
Use `-AllDlls` if you want the broader copy-all runtime approach.
By default, the zip tag is auto-derived from the built binary `--version`
output (same `VERSION_FULL` shown in Help -> About, for example
`0.7.1-dev-b7042b77`).
Use `-Version vX.Y.Z-<commit>` to override the tag explicitly.

The zip is written to `dist/` by default.
The script also writes `dist/SHA256SUMS.txt` and a companion
`<zip>.sha256` file.

To publish to GitHub Releases with assets (zip + checksums):

```powershell
./build-aux/windows/6-publish-github-release.ps1 -Tag v0.7.1-dev-b7042b77 -Version 0.7.1-dev-b7042b77
```

Optional flags:

- `-Draft`
- `-PreRelease`
- `-CreateTag` (creates and pushes the tag before publishing)

## Custom Themes on Windows

Mousepad now auto-loads style schemes from `*.xml` files found in these
locations (when present):

- `themes` (repo root, for development runs)
- `<builddir>/themes` (staged runtime)
- `MOUSEPAD_THEME_DIRECTORY` (optional override, supports multiple paths)

## Custom Language Specs on Windows

Mousepad now auto-loads GtkSourceView language specs from `*.lang` and
`*.xml` files found in these locations (when present). The language schema
file `language2.rng` must be present in the same directory:

- `language-specs` (repo root, for development runs)
- `<builddir>/language-specs` (staged runtime)
- `MOUSEPAD_LANGUAGE_SPEC_DIRECTORY` (optional override, supports multiple paths)

To add language specs, drop GtkSourceView language XML files into
`language-specs/`, re-run `./build-aux/windows/2-compile.ps1`, then start
Mousepad.

You can also configure additional search paths through the setting
`preferences.view.language-specs-directory`.

To add a theme, drop a GtkSourceView style scheme XML file into `themes/`,
re-run `./build-aux/windows/2-compile.ps1`, then start Mousepad.

The committed default theme XMLs are sourced from GtkSourceView 4 styles
(`Q:\gtk3\share\gtksourceview-4\styles` in this workflow). See
`themes/README.md` for provenance and refresh instructions.

## Crash Debugging (WinDbg/cdb)

For access violations and similar hard crashes:

```powershell
$cdb = @(
	'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe',
	'C:\Program Files\Windows Kits\10\Debuggers\x64\cdb.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $cdb) {
	$cdb = (Get-Command cdb -ErrorAction SilentlyContinue).Source
}

if (-not $cdb) {
	throw 'cdb.exe not found. Install Debugging Tools for Windows or add cdb to PATH.'
}

& $cdb -o -G -g -logo build-msvc\mousepad\cdb.log -- build-msvc\mousepad\mousepad.exe --disable-server
```

If `cdb.exe` is unavailable, use `windbgx` (WinDbg UI) to launch
`build-msvc/mousepad/mousepad.exe` and capture the first-chance exception.

## Font Warning on Windows

A warning such as `couldn't load font "Adwaita Mono 11"` is usually a fallback,
not a fatal error. Choose an installed Windows monospace font (for example
`Consolas 10`) in Mousepad preferences if you want to silence it.

## Settings on Windows (Keyfile Backend)

Windows builds in this flow use `-Dkeyfile-settings=true`, so settings are
stored in a local config file instead of desktop dconf/gsettings services.

Default settings file location when launched via `3-run.ps1` or
`mousepad\\run-mousepad.cmd`:

- `<builddir>\\config-home\\Mousepad\\settings.conf`

Fallback settings file location when `XDG_CONFIG_HOME` is not set:

- `%APPDATA%\Mousepad\settings.conf`

To override the config location per run:

```powershell
./build-aux/windows/3-run.ps1 -BuildDir build-msvc -ConfigHome Q:\tmp\mousepad-config
```

You can read/write settings directly through `mousepad.exe`:

```powershell
# Read one setting
./build-msvc/mousepad/mousepad.exe --get-setting preferences.window.menubar-visible

# Set one setting
./build-msvc/mousepad/mousepad.exe --set-setting preferences.window.menubar-visible=true

# Reset to schema default
./build-msvc/mousepad/mousepad.exe --reset-setting preferences.window.menubar-visible
```

These commands work directly on the staged executable after
`./build-aux/windows/2-compile.ps1`.

The `--set-setting` form is `SETTING=VALUE`.
For booleans, accepted values are `true/false`, `yes/no`, and `1/0`.

## Notes

- Linux desktop metadata files remain in the tree and do not block Windows compilation.
- Existing MinGW cross setup file remains available in this directory for optional use.
