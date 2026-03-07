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

## Fast path (MSVC)

Recommended one-shot bootstrap (checks toolchain and pkg-config deps, then configures):

```powershell
./build-aux/windows/bootstrap.ps1 -BuildDir build-msvc
./build-aux/windows/2-compile.ps1 -BuildDir build-msvc
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

That helper exports:

- `PKG_CONFIG_PATH=<prefix>/lib/pkgconfig:<prefix>/share/pkgconfig`
- `PATH=<prefix>/bin:...`

## Notes

- Linux desktop metadata files remain in the tree and do not block Windows compilation.
- Existing MinGW cross setup file remains available in this directory for optional use.
