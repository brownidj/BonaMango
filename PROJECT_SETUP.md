# BonaManĝo local project

PyCharm project: `/Users/david/PycharmProjects/bona_manĝo`.
Visible app name: **BonaManĝo**. Python module and Flutter package names use
`bona_mangxo` / `bona_mangxo_app`; Apple and Android app ID is
`org.topository.bonamangxo`. The Apple ID must be registered separately before
physical-device/App Store distribution. No store record, upload or invitation
was created for this project.

This is an independent code and catalogue copy, with its own virtual environment,
database, pairing key, Keychain namespace, server proof protocol, build output,
and service port **8776**. It contains a snapshot of 503 restaurant records.
Existing installed apps do not automatically share data with this new app ID.

Open this folder in PyCharm and select `.venv/bin/python` as the interpreter if
prompted. A local service run configuration is included.

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo'
./scripts/run_tests.zsh
.venv/bin/python restaurant_server.py
```

Flutter UI:

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo/flutter_app'
flutter run -d macos
```

The test runner uses `dart analyze`: this installed Flutter version's
`flutter analyze` wrapper miscalculates an LSP message length with the `ĝ` in
the working directory. Direct Dart analysis works without changing the folder
name or modifying the SDK. Golden screenshots are regenerated and visually
reviewed for the new name and icon, then the full Flutter suite is run normally.

Master icon: `assets/images/icons/bona-mangxo.png`. See the adjacent README for
the generation prompt. Flutter and all native launcher assets use this artwork.

macOS uses the ASCII executable/bundle filename `BonaMangxo.app` to avoid a
Unicode normalization failure in codesigning. Both CFBundleName and
CFBundleDisplayName remain **BonaManĝo**, as does the UI.

Project folder and PyCharm module files were renamed to `bona_manĝo`. Updated
source/documentation paths, virtual-environment launchers, editable package paths
and Flutter metadata. Python imports, pip and Flutter dependency resolution were
checked after the move. Tests/builds were not rerun for this path-only rename.
ASCII package and executable names remain `bona_mangxo` / `BonaMangxo` for tool
compatibility; the visible app name remains BonaManĝo.

PyCharm configuration repair: removed the parent-folder content root, attached
unrelated modules, Django facets and unrelated Git mappings. The project tree
was visually verified to contain only bona_manĝo. Previous IDE metadata was
retained under ignored data/backups; no sibling project files were changed.
