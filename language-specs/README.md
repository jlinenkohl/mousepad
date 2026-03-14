# Mousepad Language Specs (GtkSourceView)

This directory is for optional, repo-local GtkSourceView language definition
files (`*.lang`, `*.xml`) used during development runs.

Include `language2.rng` in this directory as well; GtkSourceView validates
language files against this schema.

## Source

Language spec files can be copied from GtkSourceView:

- https://gitlab.gnome.org/GNOME/gtksourceview/-/tree/master/data/language-specs

## Development discovery

Mousepad scans these locations for additional language specs:

- `language-specs` (repo root)
- `build-msvc/language-specs` (staged runtime)
- `MOUSEPAD_LANGUAGE_SPEC_DIRECTORY` (optional, multi-path)

On Windows, `build-aux/windows/2-compile.ps1` stages
`language-specs/*.{lang,xml}` into `build-msvc/language-specs` automatically.
If present, `language2.rng` is staged too.
