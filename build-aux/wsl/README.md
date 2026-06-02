# WSL Non-Installed Build Runner

Use this script to build and run Mousepad in WSL without running `meson install`.
It keeps runtime schemas and settings local to the selected build directory.

## Script

- `build-aux/wsl/dev-build-run.sh`

## What it does

- Configures Meson when needed.
- Optionally passes `-Dc_link_args=-lm` at setup/reconfigure time.
- Compiles the project.
- Creates a build-local schema cache in `<builddir>/runtime-schemas`.
- Uses build-local settings in `<builddir>/config-home`.

## Typical usage

- Build and run with defaults:
  - `bash build-aux/wsl/dev-build-run.sh`
- Build only:
  - `bash build-aux/wsl/dev-build-run.sh --no-run`
- Reconfigure and keep running:
  - `bash build-aux/wsl/dev-build-run.sh --configure`
- Pass args to mousepad:
  - `bash build-aux/wsl/dev-build-run.sh -- --version`

## Notes

- Default build directory is `build-wsl`.
- Use `--build-dir` to isolate multiple build trees.
- Use `--no-libm` if you do not want `-Dc_link_args=-lm` during setup.
