param(
  [string]$BuildDir = "build-msvc",
  [string]$NativeFile = "$(Join-Path $PSScriptRoot 'msvc-gtk.native.ini')"
)

$ErrorActionPreference = 'Stop'

meson setup $BuildDir `
  --native-file $NativeFile `
  -Dshortcuts-plugin=disabled `
  -Dgspell-plugin=disabled `
  -Dpolkit=disabled `
  -Dtest-plugin=disabled `
  -Dkeyfile-settings=true
