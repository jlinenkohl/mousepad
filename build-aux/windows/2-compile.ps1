param(
  [string]$BuildDir = "build-msvc",
  [string]$GtkPrefix = "Q:\gtk3"
)

$ErrorActionPreference = 'Stop'

meson compile -C $BuildDir

$schemaSrc = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')) 'mousepad\org.xfce.mousepad.gschema.xml'
$schemaDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')) "$BuildDir\runtime-schemas"
$glibCompileSchemas = Join-Path $GtkPrefix 'bin\glib-compile-schemas.exe'

if ((Test-Path $schemaSrc) -and (Test-Path $glibCompileSchemas)) {
  New-Item -ItemType Directory -Force -Path $schemaDir | Out-Null
  Copy-Item $schemaSrc (Join-Path $schemaDir 'org.xfce.mousepad.gschema.xml') -Force
  & $glibCompileSchemas $schemaDir | Out-Null
}
