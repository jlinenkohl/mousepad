param(
  [string]$BuildDir = "build-msvc"
)

$ErrorActionPreference = 'Stop'

meson compile -C $BuildDir
