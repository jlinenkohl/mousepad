param(
  [string]$BuildDir = "build-msvc",
  [string]$NativeFile = "$(Join-Path $PSScriptRoot 'msvc-gtk.native.ini')"
)

$ErrorActionPreference = 'Stop'

function Invoke-Meson {
  param([Parameter(Mandatory = $true)][string[]]$MesonArgs)

  $mesonExe = 'C:\Program Files\Meson\meson.exe'

  if (Get-Command meson -ErrorAction SilentlyContinue) {
    & meson @MesonArgs
    return
  }

  if (Test-Path $mesonExe) {
    & $mesonExe @MesonArgs
    return
  }

  if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -m mesonbuild.meson @MesonArgs
    return
  }

  if (Get-Command python -ErrorAction SilentlyContinue) {
    & python -m mesonbuild.meson @MesonArgs
    return
  }

  throw "Meson was not found. Install Meson and ensure PATH includes meson.exe (or py/python launcher)."
}

Invoke-Meson @(
  'setup',
  $BuildDir,
  '--native-file', $NativeFile,
  '-Dshortcuts-plugin=disabled',
  '-Dgspell-plugin=disabled',
  '-Dpolkit=disabled',
  '-Dtest-plugin=disabled',
  '-Dkeyfile-settings=true'
)
