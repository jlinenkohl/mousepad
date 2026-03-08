param(
  [string]$BuildDir = "build-msvc",
  [string]$GtkPrefix = "Q:\gtk3",
  [string]$GettextPrefix = "$env:LOCALAPPDATA\Programs\gettext-iconv",
  [switch]$NoStageRuntime
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

Invoke-Meson @('compile', '-C', $BuildDir)

$schemaSrc = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')) 'mousepad\org.xfce.mousepad.gschema.xml'
$schemaDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')) "$BuildDir\runtime-schemas"
$glibCompileSchemas = Join-Path $GtkPrefix 'bin\glib-compile-schemas.exe'

if ((Test-Path $schemaSrc) -and (Test-Path $glibCompileSchemas)) {
  New-Item -ItemType Directory -Force -Path $schemaDir | Out-Null
  Copy-Item $schemaSrc (Join-Path $schemaDir 'org.xfce.mousepad.gschema.xml') -Force
  & $glibCompileSchemas $schemaDir | Out-Null
}

if (-not $NoStageRuntime) {
  & (Join-Path $PSScriptRoot '4-stage-runtime.ps1') -BuildDir $BuildDir -GtkPrefix $GtkPrefix -GettextPrefix $GettextPrefix
}
