param(
  [string]$BuildDir = "build-msvc",
  [string]$GtkPrefix = "Q:\gtk3",
  [string]$NativeFile = "$(Join-Path $PSScriptRoot 'msvc-gtk.native.ini')"
)

$ErrorActionPreference = 'Stop'

function Test-CommandAvailable {
  param([Parameter(Mandatory = $true)][string]$Name)

  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  return $null -ne $cmd
}

function Assert-Command {
  param([Parameter(Mandatory = $true)][string]$Name)

  if (-not (Test-CommandAvailable -Name $Name)) {
    throw "Required command '$Name' not found in PATH. Open a VS Developer shell and/or install dependencies."
  }
}

function Assert-PkgConfigPackage {
  param([Parameter(Mandatory = $true)][string]$Package)

  & pkg-config --exists $Package
  if ($LASTEXITCODE -ne 0) {
    throw "Missing pkg-config package '$Package'. Check PKG_CONFIG_PATH and installed GTK dev packages."
  }
}

if ($GtkPrefix) {
  $pkgConfigPaths = @(
    (Join-Path $GtkPrefix 'lib/pkgconfig'),
    (Join-Path $GtkPrefix 'share/pkgconfig')
  ) -join ';'

  if ($env:PKG_CONFIG_PATH) {
    $env:PKG_CONFIG_PATH = "$pkgConfigPaths;$env:PKG_CONFIG_PATH"
  } else {
    $env:PKG_CONFIG_PATH = $pkgConfigPaths
  }

  $gtkBin = Join-Path $GtkPrefix 'bin'
  $env:Path = "$gtkBin;$env:Path"
}

Assert-Command -Name 'cl'
Assert-Command -Name 'lib'
Assert-Command -Name 'rc'
Assert-Command -Name 'meson'
Assert-Command -Name 'pkg-config'

Assert-PkgConfigPackage -Package 'gtk+-3.0'
Assert-PkgConfigPackage -Package 'glib-2.0'
Assert-PkgConfigPackage -Package 'gio-2.0'
Assert-PkgConfigPackage -Package 'gmodule-2.0'

$hasGtkSource4 = $true
& pkg-config --exists 'gtksourceview-4'
if ($LASTEXITCODE -ne 0) {
  $hasGtkSource4 = $false
}

if (-not $hasGtkSource4) {
  Assert-PkgConfigPackage -Package 'gtksourceview-3.0'
}

Write-Host "Environment checks passed. Configuring build dir '$BuildDir'..."
& (Join-Path $PSScriptRoot '1-configure-no-xfce.ps1') -BuildDir $BuildDir -NativeFile $NativeFile
