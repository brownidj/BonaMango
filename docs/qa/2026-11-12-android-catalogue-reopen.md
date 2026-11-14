# Android catalogue reopen fix

The Pixel 8 AVD displayed an empty catalogue after reopening. Android logcat
reported `Row too big to fit into CursorWindow` for the query selecting the full
JSON catalogue document. The first launch could seed successfully, while the next
process could not read that same oversized field.

`SqliteCatalogueStore.read` now selects the document length and reads 64 Ki
characters per query inside one transaction. SQLite slices the text before it
crosses Android's cursor window. Unicode is preserved. The version-1 schema,
file, scope, queued edits and conflict history are retained; no reset, deletion
or reseeding of an existing catalogue is required. Writes remain atomic.

Validation:

- Dart analysis: no issues.
- Ten host persistence/packaged-catalogue tests passed.
- Three Android emulator integration tests passed, including a multi-megabyte
  legacy-layout document with Esperanto/emoji, pending changes and conflict
  history, followed by a write and another database reopen.
- Existing native offline edit/review/add/conflict/delete and secure pairing
  persistence checks passed on Android.

The Android regression test creates its own version-1 fixture database and does
not replace the user's catalogue. The fixed normal APK is installed with
`adb install -r`, preserving existing app storage.

After reinstalling the normal app, repeated force-stop/cold-start launches
successfully displayed the existing restaurant catalogue, with no pending
changes. No Flutter errors or fatal exceptions appeared in the inspected launch
log. Local screenshot: `data/logs/android-launch/pixel8-reopen-fixed.png`.
