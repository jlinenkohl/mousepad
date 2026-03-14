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
$buildThemesDir = Join-Path $repoRoot "$BuildDir\themes"
$repoThemesDir = Join-Path $repoRoot 'themes'
$buildLanguageSpecsDir = Join-Path $repoRoot "$BuildDir\language-specs"
$repoLanguageSpecsDir = Join-Path $repoRoot 'language-specs'

if (-not (Test-Path $exePath)) {
  throw "Executable not found at '$exePath'. Run build-aux/windows/2-compile.ps1 first."
}

$gtkBin = Join-Path $GtkPrefix 'bin'
$gtkShare = Join-Path $GtkPrefix 'share'
if (-not (Test-Path $gtkBin)) {
  throw "GTK bin directory not found at '$gtkBin'."
}

# Ensure GTK runtime DLLs are available at process launch.
$env:Path = "$gtkBin;$env:Path"

# Ensure data files (icons, gtksourceview styles/languages, etc.) are discoverable.
if (Test-Path $gtkShare) {
  if ($env:XDG_DATA_DIRS) {
    $env:XDG_DATA_DIRS = "$gtkShare;$env:XDG_DATA_DIRS"
  }
  else {
    $env:XDG_DATA_DIRS = $gtkShare
  }
}

if ($GettextPrefix -and (Test-Path (Join-Path $GettextPrefix 'bin'))) {
  $env:Path = "$(Join-Path $GettextPrefix 'bin');$env:Path"
}

if (Test-Path $pluginDir) {
  $env:MOUSEPAD_PLUGIN_DIRECTORY = $pluginDir
}

if (Test-Path $buildThemesDir) {
  $env:MOUSEPAD_THEME_DIRECTORY = $buildThemesDir
}
elseif (Test-Path $repoThemesDir) {
  $env:MOUSEPAD_THEME_DIRECTORY = $repoThemesDir
}

if (Test-Path $buildLanguageSpecsDir) {
  $env:MOUSEPAD_LANGUAGE_SPEC_DIRECTORY = $buildLanguageSpecsDir
}
elseif (Test-Path $repoLanguageSpecsDir) {
  $env:MOUSEPAD_LANGUAGE_SPEC_DIRECTORY = $repoLanguageSpecsDir
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
  $exitCode = $LASTEXITCODE
  if ($null -eq $exitCode) {
    $exitCode = 0
  }

  exit $exitCode
}
else {
  Start-Process -FilePath $exePath -WorkingDirectory $exeDir | Out-Null
}
