#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: build-aux/wsl/dev-build-run.sh [options] [-- mousepad-args...]

Build and run Mousepad in WSL without installing, with build-local schema and
settings locations.

Options:
  --build-dir DIR   Build directory (default: build-wsl)
  --profile NAME    Isolated profile name (default: dev)
  --system-profile  Do not override XDG config/data locations
  --configure       Force meson setup --reconfigure before compile
  --clean           Remove build dir before configure
  --no-libm         Do not pass -Dc_link_args=-lm during setup/reconfigure
  --no-run          Build only; do not launch mousepad
  -h, --help        Show this help

Examples:
  build-aux/wsl/dev-build-run.sh
  build-aux/wsl/dev-build-run.sh --build-dir build-wsl-debug -- --version
  build-aux/wsl/dev-build-run.sh --configure --no-run
EOF
}

BUILD_DIR="build-wsl"
PROFILE="dev"
SYSTEM_PROFILE=0
FORCE_CONFIGURE=0
CLEAN_BUILD=0
USE_LIBM=1
RUN_AFTER_BUILD=1
APP_ARGS=()

while (($#)); do
  case "$1" in
    --build-dir)
      if (($# < 2)); then
        echo "Error: --build-dir requires a value" >&2
        exit 2
      fi
      BUILD_DIR="$2"
      shift 2
      ;;
    --profile)
      if (($# < 2)); then
        echo "Error: --profile requires a value" >&2
        exit 2
      fi
      PROFILE="$2"
      shift 2
      ;;
    --system-profile)
      SYSTEM_PROFILE=1
      shift
      ;;
    --configure)
      FORCE_CONFIGURE=1
      shift
      ;;
    --clean)
      CLEAN_BUILD=1
      shift
      ;;
    --no-libm)
      USE_LIBM=0
      shift
      ;;
    --no-run)
      RUN_AFTER_BUILD=0
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    --)
      shift
      APP_ARGS=("$@")
      break
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      show_help >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_PATH="$REPO_ROOT/$BUILD_DIR"
SCHEMA_SRC="$REPO_ROOT/mousepad/org.xfce.mousepad.gschema.xml"
SCHEMA_DIR="$BUILD_PATH/runtime-schemas"
PROFILE_ROOT="$BUILD_PATH/profiles/$PROFILE"
CONFIG_HOME="$PROFILE_ROOT/config"
DATA_HOME="$PROFILE_ROOT/data"
BIN_PATH="$BUILD_PATH/mousepad/mousepad"

if ! command -v meson >/dev/null 2>&1; then
  echo "Error: meson not found in PATH" >&2
  exit 127
fi

if ! command -v glib-compile-schemas >/dev/null 2>&1; then
  echo "Error: glib-compile-schemas not found in PATH" >&2
  exit 127
fi

if [[ ! -f "$SCHEMA_SRC" ]]; then
  echo "Error: schema source not found: $SCHEMA_SRC" >&2
  exit 1
fi

cd "$REPO_ROOT"

if ((CLEAN_BUILD)); then
  rm -rf "$BUILD_PATH"
fi

if [[ ! -d "$BUILD_PATH" ]]; then
  SETUP_ARGS=(setup "$BUILD_DIR")
  if ((USE_LIBM)); then
    SETUP_ARGS+=("-Dc_link_args=-lm")
  fi
  meson "${SETUP_ARGS[@]}"
elif ((FORCE_CONFIGURE)); then
  SETUP_ARGS=(setup "$BUILD_DIR" --reconfigure)
  if ((USE_LIBM)); then
    SETUP_ARGS+=("-Dc_link_args=-lm")
  fi
  meson "${SETUP_ARGS[@]}"
fi

meson compile -C "$BUILD_DIR"

mkdir -p "$SCHEMA_DIR"
cp "$SCHEMA_SRC" "$SCHEMA_DIR/org.xfce.mousepad.gschema.xml"
glib-compile-schemas "$SCHEMA_DIR" >/dev/null

if (( ! SYSTEM_PROFILE )); then
  mkdir -p "$CONFIG_HOME" "$DATA_HOME"
fi

if ((RUN_AFTER_BUILD)); then
  if [[ ! -x "$BIN_PATH" ]]; then
    echo "Error: binary not found: $BIN_PATH" >&2
    exit 1
  fi

  if (( ! SYSTEM_PROFILE )); then
    export XDG_CONFIG_HOME="$CONFIG_HOME"
    export XDG_DATA_HOME="$DATA_HOME"
  fi
  if [[ -n "${GSETTINGS_SCHEMA_DIR:-}" ]]; then
    export GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR:$GSETTINGS_SCHEMA_DIR"
  else
    export GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR"
  fi

  if (( SYSTEM_PROFILE )); then
    echo "Using system profile (no XDG overrides)"
  else
    echo "Using profile '$PROFILE'"
    echo "Using XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
    echo "Using XDG_DATA_HOME=$XDG_DATA_HOME"
  fi
  echo "Using GSETTINGS_SCHEMA_DIR=$GSETTINGS_SCHEMA_DIR"

  exec "$BIN_PATH" "${APP_ARGS[@]}"
fi

echo "Build complete."
echo "Schema cache: $SCHEMA_DIR/gschemas.compiled"
if (( SYSTEM_PROFILE )); then
  echo "Profile: system"
else
  echo "Profile: $PROFILE"
  echo "Config home: $CONFIG_HOME"
  echo "Data home: $DATA_HOME"
fi
