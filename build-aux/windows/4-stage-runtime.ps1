param(
  [string]$BuildDir = "build-msvc",
  [string]$GtkPrefix = "Q:\gtk3",
  [string]$GettextPrefix = "$env:LOCALAPPDATA\Programs\gettext-iconv"
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$targetDir = Join-Path $repoRoot "$BuildDir\mousepad"
$schemaDir = Join-Path $repoRoot "$BuildDir\runtime-schemas"
$repoThemesDir = Join-Path $repoRoot 'themes'
$buildThemesDir = Join-Path $repoRoot "$BuildDir\themes"

if (-not (Test-Path $targetDir)) {
  throw "Target directory not found: '$targetDir'. Build first."
}

$gtkBin = Join-Path $GtkPrefix 'bin'
if (-not (Test-Path $gtkBin)) {
  throw "GTK bin directory not found: '$gtkBin'."
}

# Copy GTK runtime DLLs app-local so mousepad.exe can start from a plain shell.
Copy-Item (Join-Path $gtkBin '*.dll') $targetDir -Force -ErrorAction SilentlyContinue

# Copy gettext runtime DLLs if available (intl/iconv dependencies).
if ($GettextPrefix) {
  $gettextBin = Join-Path $GettextPrefix 'bin'
  if (Test-Path $gettextBin) {
    Copy-Item (Join-Path $gettextBin '*.dll') $targetDir -Force -ErrorAction SilentlyContinue
  }
}

# Stage optional editor color schemes from repo-local themes/*.xml.
if (Test-Path $repoThemesDir) {
  New-Item -ItemType Directory -Force -Path $buildThemesDir | Out-Null
  Get-ChildItem -Path $buildThemesDir -Filter '*.xml' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  Copy-Item (Join-Path $repoThemesDir '*.xml') $buildThemesDir -Force -ErrorAction SilentlyContinue
}

# Generate a self-contained launcher cmd for direct runs.
$runCmd = Join-Path $targetDir 'run-mousepad.cmd'
$cmd = @(
  '@echo off',
  'setlocal',
  'set "EXE_DIR=%~dp0"',
  'set "PATH=%EXE_DIR%;%PATH%"',
  'if exist "%EXE_DIR%..\runtime-schemas" set "GSETTINGS_SCHEMA_DIR=%EXE_DIR%..\runtime-schemas"',
  'if exist "%EXE_DIR%..\plugins" set "MOUSEPAD_PLUGIN_DIRECTORY=%EXE_DIR%..\plugins"',
  'if exist "%EXE_DIR%..\themes" set "MOUSEPAD_THEME_DIRECTORY=%EXE_DIR%..\themes"',
  '"%EXE_DIR%mousepad.exe" %*',
  'exit /b %ERRORLEVEL%'
)
$cmd | Set-Content -Path $runCmd -Encoding ASCII

Write-Host "Staged runtime DLLs into $targetDir"
Write-Host "Launcher created: $runCmd"
