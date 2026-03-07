param(
  [string]$BuildDir = "build-msvc",
  [string]$GtkPrefix = "Q:\gtk3",
  [string]$GettextPrefix = "$env:LOCALAPPDATA\Programs\gettext-iconv",
  [switch]$Wait
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$exePath = Join-Path $repoRoot "$BuildDir\mousepad\mousepad.exe"
$exeDir = Split-Path -Parent $exePath
$pluginDir = Join-Path $repoRoot "$BuildDir\plugins"

if (-not (Test-Path $exePath)) {
  throw "Executable not found at '$exePath'. Run build-aux/windows/2-compile.ps1 first."
}

$gtkBin = Join-Path $GtkPrefix 'bin'
if (-not (Test-Path $gtkBin)) {
  throw "GTK bin directory not found at '$gtkBin'."
}

# Ensure GTK runtime DLLs are available at process launch.
$env:Path = "$gtkBin;$env:Path"

if ($GettextPrefix -and (Test-Path (Join-Path $GettextPrefix 'bin'))) {
  $env:Path = "$(Join-Path $GettextPrefix 'bin');$env:Path"
}

if (Test-Path $pluginDir) {
  $env:MOUSEPAD_PLUGIN_DIRECTORY = $pluginDir
}

$schemaSrc = Join-Path $repoRoot 'mousepad\org.xfce.mousepad.gschema.xml'
$schemaDir = Join-Path $repoRoot "$BuildDir\runtime-schemas"
$glibCompileSchemas = Join-Path $gtkBin 'glib-compile-schemas.exe'

if ((Test-Path $schemaSrc) -and (Test-Path $glibCompileSchemas)) {
  New-Item -ItemType Directory -Force -Path $schemaDir | Out-Null
  Copy-Item $schemaSrc (Join-Path $schemaDir 'org.xfce.mousepad.gschema.xml') -Force

  # Generate schema cache for non-installed development runs.
  & $glibCompileSchemas $schemaDir | Out-Null
  $env:GSETTINGS_SCHEMA_DIR = $schemaDir
}

Write-Host "Launching $exePath"
if ($Wait) {
  & $exePath
}
else {
  Start-Process -FilePath $exePath -WorkingDirectory $exeDir | Out-Null
}
