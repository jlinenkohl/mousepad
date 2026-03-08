# Theme Source Notes

The XML files in this folder are vendored from GtkSourceView 4 style schemes.

Exact upstream provenance for the currently committed files:

- Repository: `https://gitlab.gnome.org/GNOME/gtksourceview`
- Tag: `4.8.4`
- Commit (tag target): `7fd3adb3134bbec167167bb6400e018e4f781eb9`
- Path: `data/styles/*.xml`

These files are byte-for-byte matches to that upstream path for the files we
ship (`classic`, `cobalt`, `kate`, `oblivion`, `solarized-dark`,
`solarized-light`, `tango`).

In this fork workflow, refresh copies usually come from the local GTK prefix
used for Windows builds, from:

- `<GtkPrefix>\share\gtksourceview-4\styles\*.xml`

Example with the default scripts value:

- `Q:\gtk3\share\gtksourceview-4\styles\*.xml`

These files are intended to stay compatible with GtkSourceView 4 used by this Windows build flow.
Do not replace them with GtkSourceView 5 style files (for example files using top-level `<metadata>`),
or runtime warnings will occur and schemes may fail to load.

To refresh from your current GTK prefix:

```powershell
$GtkPrefix = 'Q:\gtk3'  # adjust if your prefix differs
Copy-Item "$GtkPrefix\share\gtksourceview-4\styles\*.xml" themes\ -Force
```
