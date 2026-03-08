# Theme Source Notes

The XML files in this folder are copied from the local GtkSourceView 4 runtime styles directory:

- `Q:\gtk3\share\gtksourceview-4\styles\*.xml`

These files are intended to stay compatible with GtkSourceView 4 used by this Windows build flow.
Do not replace them with GtkSourceView 5 style files (for example files using top-level `<metadata>`),
or runtime warnings will occur and schemes may fail to load.

To refresh from your local GTK prefix:

```powershell
Copy-Item Q:\gtk3\share\gtksourceview-4\styles\*.xml themes\ -Force
```

Note: `_tmp-gtksourceview/` is a temporary reference checkout and is not required at runtime.
