param(
  [Parameter(Mandatory = $true)]
  [string]$Tag,

  [string]$BuildDir = "build-msvc",
  [string]$OutputDir = "dist",
  [string]$PackageName = "mousepad",
  [string]$Version,
  [string]$Title,
  [string]$Notes = "Portable Windows build",
  [switch]$Draft,
  [switch]$PreRelease,
  [switch]$CreateTag,
  [switch]$TargetLatestCommit
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
if (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
  $OutputDir = Join-Path $repoRoot $OutputDir
}

$releaseScript = Join-Path $PSScriptRoot '5-create-release-package.ps1'
if (-not (Test-Path $releaseScript)) {
  throw "Missing script: $releaseScript"
}

$releaseArgs = @{
  BuildDir = $BuildDir
  OutputDir = $OutputDir
  PackageName = $PackageName
}
if ($Version) {
  $releaseArgs['Version'] = $Version
}

& $releaseScript @releaseArgs

$zip = Get-ChildItem -Path $OutputDir -Filter "$PackageName-*.zip" -File |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1
if (-not $zip) {
  throw "No release zip found in '$OutputDir'."
}

$zipSha = "$($zip.FullName).sha256"
$shaSums = Join-Path $OutputDir 'SHA256SUMS.txt'
$assets = @($zip.FullName)
if (Test-Path $zipSha) { $assets += $zipSha }
if (Test-Path $shaSums) { $assets += $shaSums }

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
  throw "GitHub CLI (gh) not found. Install gh and run 'gh auth login'."
}

if ($CreateTag) {
  if ($TargetLatestCommit) {
    git tag $Tag HEAD
  }
  else {
    git tag $Tag
  }
  git push origin $Tag
}

$finalTitle = if ([string]::IsNullOrWhiteSpace($Title)) { "Mousepad $Tag" } else { $Title }

$args = @('release', 'create', $Tag)
$args += $assets
$args += @('--title', $finalTitle, '--notes', $Notes)
if ($Draft) { $args += '--draft' }
if ($PreRelease) { $args += '--prerelease' }

& gh @args

Write-Host "Published release '$Tag' with assets:"
$assets | ForEach-Object { Write-Host "  - $_" }
