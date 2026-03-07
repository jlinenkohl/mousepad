param(
  [string]$BuildDir = "build-msvc",
  [Parameter(Mandatory = $true)]
  [string]$GtkPrefix,
  [string]$NativeFile = "$(Join-Path $PSScriptRoot 'msvc-gtk.native.ini')"
)

$ErrorActionPreference = 'Stop'

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

& (Join-Path $PSScriptRoot '1-configure-no-xfce.ps1') -BuildDir $BuildDir -NativeFile $NativeFile
