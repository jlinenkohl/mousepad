param(
  [string]$BuildDir = "build-msvc",
  [string]$GtkPrefix = "Q:\gtk3",
  [string]$GettextPrefix = "$env:LOCALAPPDATA\Programs\gettext-iconv",
  [string]$OutputDir = "dist",
  [string]$PackageName = "mousepad",
  [string]$Version,
  [switch]$AllDlls
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$buildRoot = Join-Path $repoRoot $BuildDir
$mousepadDir = Join-Path $buildRoot 'mousepad'

if (-not (Test-Path $mousepadDir)) {
  throw "Build output not found at '$mousepadDir'. Run configure/compile first."
}

$stageScript = Join-Path $PSScriptRoot '4-stage-runtime.ps1'
if (-not (Test-Path $stageScript)) {
  throw "Runtime staging script not found: '$stageScript'."
}

$stageArgs = @{
  BuildDir = $BuildDir
  GtkPrefix = $GtkPrefix
  GettextPrefix = $GettextPrefix
}

if (-not $AllDlls) {
  $stageArgs['MinimalDlls'] = $true
}

& $stageScript @stageArgs

$exePath = Join-Path $mousepadDir 'mousepad.exe'
$runCmdPath = Join-Path $mousepadDir 'run-mousepad.cmd'
if (-not (Test-Path $exePath)) {
  throw "Expected executable not found: '$exePath'."
}
if (-not (Test-Path $runCmdPath)) {
  throw "Expected launcher not found: '$runCmdPath'."
}

function Get-BuildVersionTag {
  param([string]$LauncherPath)

  $versionOutput = & $LauncherPath --version 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $versionOutput) {
    return $null
  }

  foreach ($line in $versionOutput) {
    if ($line -match '^\s*Mousepad\s+(.+?)\s*$') {
      return $matches[1].Trim()
    }
  }

  return $null
}

$dateTag = Get-Date -Format 'yyyyMMdd-HHmmss'

$releaseTag = $null
if ([string]::IsNullOrWhiteSpace($Version)) {
  $releaseTag = Get-BuildVersionTag -LauncherPath $runCmdPath
}
else {
  $releaseTag = $Version.Trim()
}

if ([string]::IsNullOrWhiteSpace($releaseTag)) {
  $releaseTag = $dateTag
}

$releaseTag = ($releaseTag -replace '[^A-Za-z0-9._-]', '-')
$releaseName = if ([string]::IsNullOrWhiteSpace($PackageName)) {
  $releaseTag
}
else {
  "$PackageName-$releaseTag"
}
$stagingRoot = Join-Path $buildRoot 'release-staging'
$packageRoot = Join-Path $stagingRoot $releaseName

if (Test-Path $stagingRoot) {
  Remove-Item -Path $stagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

$dirsToStage = @('mousepad', 'runtime-schemas', 'plugins', 'themes', 'language-specs')
foreach ($dirName in $dirsToStage) {
  $src = Join-Path $buildRoot $dirName
  if (Test-Path $src) {
    Copy-Item -Path $src -Destination (Join-Path $packageRoot $dirName) -Recurse -Force
  }
}

$copyingFile = Join-Path $repoRoot 'COPYING'
if (Test-Path $copyingFile) {
  Copy-Item $copyingFile (Join-Path $packageRoot 'COPYING.txt') -Force
}

$notes = @(
  'Mousepad Portable Build (Windows 11)',
  '',
  'Run:',
  '  mousepad\run-mousepad.cmd',
  '',
  'Notes:',
  '  - No administrator rights required for normal use.',
  '  - Runtime DLLs are staged app-local (next to mousepad.exe).',
  '  - Settings are stored under %APPDATA%\Mousepad\settings.conf.'
)
$notes | Set-Content -Path (Join-Path $packageRoot 'README-PORTABLE.txt') -Encoding ASCII

if (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
  $OutputDir = Join-Path $repoRoot $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$zipPath = Join-Path $OutputDir ($releaseName + '.zip')
if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}

Compress-Archive -Path $packageRoot -DestinationPath $zipPath -CompressionLevel Optimal

$zipName = [System.IO.Path]::GetFileName($zipPath)
$zipHash = (Get-FileHash -Algorithm SHA256 -Path $zipPath).Hash.ToLowerInvariant()
$shaLine = "$zipHash *$zipName"

$shaFile = Join-Path $OutputDir ($zipName + '.sha256')
Set-Content -Path $shaFile -Value $shaLine -Encoding ASCII

$shaSumsFile = Join-Path $OutputDir 'SHA256SUMS.txt'
$lines = @()
if (Test-Path $shaSumsFile) {
  $lines = Get-Content -Path $shaSumsFile | Where-Object { $_ -and ($_ -notmatch [regex]::Escape("*$zipName") + '$') }
}
$lines += $shaLine
$lines = $lines | Sort-Object
Set-Content -Path $shaSumsFile -Value $lines -Encoding ASCII

$zipSize = (Get-Item $zipPath).Length
$zipSizeMb = [math]::Round($zipSize / 1MB, 2)

Write-Host "Release package created: $zipPath"
Write-Host "Checksum: $zipHash"
Write-Host "Checksum files: $shaFile, $shaSumsFile"
Write-Host "Size: $zipSizeMb MB"
Write-Host "Mode: $(if ($AllDlls) { 'all GTK/gettext DLLs' } else { 'minimal recursive DLL closure' })"
Write-Host "Tag: $releaseTag"
