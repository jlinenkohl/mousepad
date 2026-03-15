param(
  [string]$BuildDir = "build-msvc",
  [string]$GtkPrefix = "Q:\gtk3",
  [string]$GettextPrefix = "$env:LOCALAPPDATA\Programs\gettext-iconv",
  [switch]$MinimalDlls
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$targetDir = Join-Path $repoRoot "$BuildDir\mousepad"
$schemaDir = Join-Path $repoRoot "$BuildDir\runtime-schemas"
$repoThemesDir = Join-Path $repoRoot 'themes'
$buildThemesDir = Join-Path $repoRoot "$BuildDir\themes"
$repoLanguageSpecsDir = Join-Path $repoRoot 'language-specs'
$buildLanguageSpecsDir = Join-Path $repoRoot "$BuildDir\language-specs"

if (-not (Test-Path $targetDir)) {
  throw "Target directory not found: '$targetDir'. Build first."
}

$gtkBin = Join-Path $GtkPrefix 'bin'
if (-not (Test-Path $gtkBin)) {
  throw "GTK bin directory not found: '$gtkBin'."
}

# Copy GTK runtime DLLs app-local so mousepad.exe can start from a plain shell.

# Remove previously staged runtime DLLs to avoid stale leftovers from earlier runs.
Get-ChildItem -Path $targetDir -Filter '*.dll' -File -ErrorAction SilentlyContinue |
  Remove-Item -Force -ErrorAction SilentlyContinue

$gettextBin = $null

# Copy gettext runtime DLLs if available (intl/iconv dependencies).
if ($GettextPrefix) {
  $candidate = Join-Path $GettextPrefix 'bin'
  if (Test-Path $candidate) {
    $gettextBin = $candidate
  }
}

function Find-DumpbinPath {
  $dumpbin = Get-Command dumpbin -ErrorAction SilentlyContinue
  if ($dumpbin) {
    return $dumpbin.Source
  }

  $roots = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC",
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC"
  )

  foreach ($root in $roots) {
    if (-not (Test-Path $root)) {
      continue
    }

    $candidate = Get-ChildItem -Path $root -Recurse -Filter dumpbin.exe -File -ErrorAction SilentlyContinue |
      Select-Object -First 1 -ExpandProperty FullName
    if ($candidate) {
      return $candidate
    }
  }

  return $null
}

function Get-PeDependents {
  param(
    [string]$DumpbinPath,
    [string]$BinaryPath
  )

  $output = & $DumpbinPath /dependents $BinaryPath 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $output) {
    return @()
  }

  $deps = New-Object System.Collections.Generic.List[string]
  foreach ($line in $output) {
    if ($line -match '^\s+([A-Za-z0-9_.-]+\.dll)\s*$') {
      $deps.Add($matches[1])
    }
  }

  return $deps
}

if ($MinimalDlls) {
  $dumpbinPath = Find-DumpbinPath
  if (-not $dumpbinPath) {
    throw "dumpbin.exe not found. Install Visual Studio C++ tools or run from a VS Developer shell."
  }

  $sourceBins = New-Object System.Collections.Generic.List[string]
  $sourceBins.Add($gtkBin)
  if ($gettextBin) {
    $sourceBins.Add($gettextBin)
  }

  $dllMap = @{}
  foreach ($binDir in $sourceBins) {
    Get-ChildItem -Path $binDir -Filter '*.dll' -File -ErrorAction SilentlyContinue | ForEach-Object {
      if (-not $dllMap.ContainsKey($_.Name.ToLowerInvariant())) {
        $dllMap[$_.Name.ToLowerInvariant()] = $_.FullName
      }
    }
  }

  $seedBinaries = New-Object System.Collections.Generic.List[string]
  $mainExe = Join-Path $targetDir 'mousepad.exe'
  if (-not (Test-Path $mainExe)) {
    throw "Executable not found: '$mainExe'."
  }
  $seedBinaries.Add($mainExe)

  $pluginsDir = Join-Path $repoRoot "$BuildDir\plugins"
  if (Test-Path $pluginsDir) {
    Get-ChildItem -Path $pluginsDir -Filter '*.dll' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      $seedBinaries.Add($_.FullName)
    }
  }

  $visitedBins = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  $depsToCopy = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  $queue = New-Object System.Collections.Generic.Queue[string]
  foreach ($seed in $seedBinaries) {
    $queue.Enqueue($seed)
  }

  while ($queue.Count -gt 0) {
    $binPath = $queue.Dequeue()
    if (-not $visitedBins.Add($binPath)) {
      continue
    }

    foreach ($depName in (Get-PeDependents -DumpbinPath $dumpbinPath -BinaryPath $binPath)) {
      $depKey = $depName.ToLowerInvariant()
      if ($dllMap.ContainsKey($depKey) -and $depsToCopy.Add($dllMap[$depKey])) {
        $queue.Enqueue($dllMap[$depKey])
      }
    }
  }

  foreach ($depPath in $depsToCopy) {
    Copy-Item $depPath $targetDir -Force -ErrorAction SilentlyContinue
  }

  Write-Host "Minimal DLL staging enabled: copied $($depsToCopy.Count) recursive dependency DLL(s)."
}
else {
  Copy-Item (Join-Path $gtkBin '*.dll') $targetDir -Force -ErrorAction SilentlyContinue

  if ($gettextBin) {
    Copy-Item (Join-Path $gettextBin '*.dll') $targetDir -Force -ErrorAction SilentlyContinue
  }
}

# Stage optional editor color schemes from repo-local themes/*.xml.
if (Test-Path $repoThemesDir) {
  New-Item -ItemType Directory -Force -Path $buildThemesDir | Out-Null
  Get-ChildItem -Path $buildThemesDir -Filter '*.xml' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  Copy-Item (Join-Path $repoThemesDir '*.xml') $buildThemesDir -Force -ErrorAction SilentlyContinue
}

# Stage optional editor language specs from repo-local language-specs/*.xml.
if (Test-Path $repoLanguageSpecsDir) {
  New-Item -ItemType Directory -Force -Path $buildLanguageSpecsDir | Out-Null
  Get-ChildItem -Path $buildLanguageSpecsDir -Filter '*.xml' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  Get-ChildItem -Path $buildLanguageSpecsDir -Filter '*.lang' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  Get-ChildItem -Path $buildLanguageSpecsDir -Filter '*.rng' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  Copy-Item (Join-Path $repoLanguageSpecsDir '*.xml') $buildLanguageSpecsDir -Force -ErrorAction SilentlyContinue
  Copy-Item (Join-Path $repoLanguageSpecsDir '*.lang') $buildLanguageSpecsDir -Force -ErrorAction SilentlyContinue
  Copy-Item (Join-Path $repoLanguageSpecsDir '*.rng') $buildLanguageSpecsDir -Force -ErrorAction SilentlyContinue
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
  'if exist "%EXE_DIR%..\language-specs" set "MOUSEPAD_LANGUAGE_SPEC_DIRECTORY=%EXE_DIR%..\language-specs"',
  '"%EXE_DIR%mousepad.exe" %*',
  'exit /b %ERRORLEVEL%'
)
$cmd | Set-Content -Path $runCmd -Encoding ASCII

Write-Host "Staged runtime DLLs into $targetDir"
Write-Host "Launcher created: $runCmd"
