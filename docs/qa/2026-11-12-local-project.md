# BonaManĝo local project — 12 November 2026

Goal: create a separate PyCharm project at `/Users/david/PycharmProjects/bona_manĝo`
with copied restaurant functionality, the BonaManĝo name and photorealistic blue
mango branding. Preserve the source project and keep data, credentials and
runtime identity independent.

## Implementation

- Created an independent Python virtual environment, editable package and PyCharm
  configuration; opened the project in PyCharm.
- Copied code, tests, fonts, documentation and consistent SQLite snapshots.
  The packaged starting catalogue contains 503 restaurants and saved evidence.
- Replaced former branding in source paths, imports, classes, UI, docs, protocol
  headers/proofs, application IDs and platform configuration.
- Use ASCII `bona_mangxo` / `bona_mangxo_app` for module/package identifiers,
  `org.topository.bonamangxo` for native app IDs, and BonaManĝo for visible names.
- Service defaults and mobile configuration use port 8776. A new private pairing
  key was generated; the source key is not copied or included in the app assets.
- Master artwork is `assets/images/icons/bona-mangxo.png`; the Flutter image and
  iOS/macOS/Android/web/Windows launcher assets are exports of that master.
- Reviewed phone, small-phone and large-text golden screenshots; kept the brand
  on one line at large text scale and regenerated all four visual baselines.
- Updated native integration expectations for automatic sync-modal dismissal and
  immediate sync after a confirmed deletion.

## Verification

- Python: 101 tests passed.
- Flutter: 71 tests passed, including four golden baselines.
- Direct Dart analysis: no issues found.
- Native iOS integration: 2 tests passed on iPhone 17 Pro simulator, iOS 26.5,
  including real SQLite persistence, offline changes, conflict resolution,
  confirmed deletion, quiet idle sync and native Keychain persistence.
- Web release compilation passed; iOS simulator compilation passed.
- Apple plist/project syntax and zsh script syntax passed.
- No previous brand name remains in the copied source/documentation or seeded
  restaurant text. Generated files and test fixtures use the new identity.

Flutter's analyze wrapper failed on this machine because its LSP request was
truncated for the Unicode path. The project runner uses direct `dart analyze`,
which passed. The SDK and requested folder name are unchanged. Pairing fixtures
now declare UTF-8 JSON explicitly to support the `ĝ` in the service name.

Logs: `data/logs/project-setup/` and the test runner's dated log folder.
No live restaurant/server edits or paid discovery requests were used in tests.
No Apple registration, production device deployment or store upload was performed.
Android, Windows and Linux native builds remain unverified on this Mac.

Phase: not applicable. No Git commit was created.
Suggested commit: `Create BonaManĝo app with blue mango branding and isolated local configuration`.

Final native branding check: macOS debug build passed and its code signature was
verified. The executable/bundle filename uses ASCII `BonaMangxo.app` because
codesigning failed with a Unicode executable name; CFBundleName and
CFBundleDisplayName are both BonaManĝo. Verified the compiled native icon. The
final web release package contains the correct display name, mango asset and
503-record seed. All build output is separate from the source app.
