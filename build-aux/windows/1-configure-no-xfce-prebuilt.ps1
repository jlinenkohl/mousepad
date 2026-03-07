param(
  [string]$BuildDir = "build-msvc",
  [Parameter(Mandatory = $true)]
  [string]$GtkPrefix,
  [string]$GettextPrefix = "$env:LOCALAPPDATA\Programs\gettext-iconv",
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

if ($GettextPrefix -and (Test-Path (Join-Path $GettextPrefix 'bin/msgfmt.exe'))) {
  $gettextBin = Join-Path $GettextPrefix 'bin'

  # Ensure msgfmt/msgmerge/msginit/xgettext come from the same gettext prefix.
  $env:Path = "$gettextBin;$gtkBin;$env:Path"

  $itsSource = Join-Path $GettextPrefix 'share/gettext/its/metainfo.its'
  if (Test-Path $itsSource) {
    $overlayItsDir = Join-Path $PSScriptRoot '.gettext-overlay/share/gettext/its'
    New-Item -ItemType Directory -Force -Path $overlayItsDir | Out-Null
    Copy-Item $itsSource (Join-Path $overlayItsDir 'metainfo.its') -Force

    # Some Windows gettext builds miss AppStream locating rules for *.appdata.xml[.in].
    @'
<?xml version="1.0"?>
<locatingRules>
  <locatingRule name="AppStream metainfo" pattern="*.metainfo.xml">
    <documentRule localName="component" target="metainfo.its"/>
    <documentRule ns="https://specifications.freedesktop.org/metainfo/1.0" localName="component" target="metainfo.its"/>
  </locatingRule>
  <locatingRule name="AppStream appdata legacy" pattern="*.appdata.xml">
    <documentRule localName="component" target="metainfo.its"/>
    <documentRule ns="https://specifications.freedesktop.org/metainfo/1.0" localName="component" target="metainfo.its"/>
  </locatingRule>
  <locatingRule name="AppStream appdata template" pattern="*.appdata.xml.in">
    <documentRule localName="component" target="metainfo.its"/>
    <documentRule ns="https://specifications.freedesktop.org/metainfo/1.0" localName="component" target="metainfo.its"/>
  </locatingRule>
</locatingRules>
'@ | Set-Content -Path (Join-Path $overlayItsDir 'metainfo.loc') -Encoding UTF8

    $overlayPrefix = Join-Path $PSScriptRoot '.gettext-overlay'
    if ($env:GETTEXTDATADIRS) {
      $env:GETTEXTDATADIRS = "$overlayPrefix;$GettextPrefix;$env:GETTEXTDATADIRS"
    } else {
      $env:GETTEXTDATADIRS = "$overlayPrefix;$GettextPrefix"
    }
  }
}
else {
  $env:Path = "$gtkBin;$env:Path"
}

& (Join-Path $PSScriptRoot '1-configure-no-xfce.ps1') -BuildDir $BuildDir -NativeFile $NativeFile
