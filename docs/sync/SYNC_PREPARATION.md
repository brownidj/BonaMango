# Preparation for changing the sync provider

Updated: 12 November 2026.

This work can be used with Ditto or another provider. The current authenticated
HTTP sync remains the default. No Ditto SDK, licence or credentials are installed,
and no existing database is migrated. Phase 0's licensing and physical radio
tests remain prerequisites for adopting Ditto.

Current direction (14 November 2026): [Apple LAN/direct Wi-Fi plan](APPLE_LOCAL_SYNC_IMPLEMENTATION_PLAN.md).
Bluetooth transport is deferred and Ditto is not the selected provider under the
zero-cost requirement. The implementation boundaries below are retained.

## Implemented boundaries

- `flutter_app/lib/data/catalogue_store.dart` defines `CatalogueStore`. A write
  atomically persists the snapshot, pending operations and conflict history.
  `SqliteCatalogueStore` remains the implementation, with the same database path,
  scope and document format. Its old module re-exports the interface so existing
  consumers continue to work. Store owners manage database closure.
- `flutter_app/lib/services/catalogue_transport.dart` defines `CatalogueTransport`
  and `CatalogueReply`. The controller consumes structured application responses
  rather than sending HTTP or decoding remote JSON itself. The default
  `HttpCatalogueTransport` borrows the existing authenticated client, preserving
  server verification, pairing, edit headers, revisions and error statuses.
- `MobileCatalogue` accepts an injected transport. Its six-second timeout, local
  projection, durable outbox, editing barrier, dirty flag and conflict resolution
  remain in the controller. Existing repository/UI calls still use the local HTTP
  compatibility facade. Unhandled endpoints retain their current remote route.

This is an incremental boundary, not a complete provider migration. Operation
names/paths and numeric response statuses retain the existing host protocol.
A future mesh adapter must translate host acceptance receipts to these replies;
transport delivery alone cannot count as a saved host record. It must implement
snapshot versioning and dependent-operation ID/revision remapping equivalently.
The injected transport's owner manages its resources. The controller continues to
close its existing HTTP client when disposed.

Before changing persisted IDs or replacing the snapshot with mesh documents,
implement an explicit, backed-up migration with exactly-once replay of existing
pending operations and full retention of source evidence and conflict history.
The current HTTP fallback must remain available during that transition.

## Regression coverage

`flutter_app/test/catalogue_transport_test.dart` adds five checks:

1. HTTP encoding preserves Unicode, edit payloads and conflict responses.
2. Malformed response envelopes are rejected.
3. A transport fake with no HTTP preserves offline pending edits across controller
   restart, detects a newer host revision, stops automatic conflict retries and
   retains both versions after an explicit keep-local decision.
4. Opening an editor waits for an in-flight download. Further refreshes cannot
   replace its record; Cancel causes no upload or refresh.
5. Idle and network-return triggers cannot upload a saved review while its flow
   remains open; closing the saved flow uploads it once.

Existing real SQLite restart, two-client conflict, lost-response, idempotent add,
failed-write, stale-editor and nested review/edit tests remain in the full suite.
The fake is not evidence of Ditto activation, radio transport or SDK compatibility.

Run the complete host and iOS simulator suite from the project root:

```zsh
./scripts/run_tests.zsh --all
```

## Android preparation

The Android app explicitly uses minimum API 31 (Android 12), target API 36
(Android 16) and compile API 36. Package identity is unchanged. The raised minimum
means Android 11 and older cannot install future builds.

No Bluetooth or nearby-device permissions are requested yet: no radio provider is
implemented. Permission handling, denial recovery, LAN access and BLE background
behaviour must be implemented and tested with the selected provider. Android
release signing is also not configured; the template's debug signing is unsuitable
for production distribution.

Build a development APK after configuring Android SDK tools and licences:

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo/flutter_app'
flutter build apk --debug
```

Qualify installation, offline launch, edit/review persistence, maps/browser/dialer,
network rejoin and denied permissions on Android 12 and a current Android version.
Test real BLE exchange with the Mac and iPhone on physical Android hardware;
emulators cannot qualify that capability. This preparation does not claim Android
or Bluetooth production support.

## Verification on 12 November 2026

`./scripts/run_tests.zsh --all` passed:

- 101 Python tests, including real HTTP/SQLite integration.
- Dart analysis with no issues.
- 76 Flutter unit/widget/golden tests, including the five new transport checks.
- Both native iOS simulator integration tests on iPhone 17 Pro / iOS 26.5.

The native tests cover offline SQLite, editing/review, add/reopen, conflict
resolution, delete and secure pairing persistence. Ignored detailed logs are in
`data/logs/testing-2026-11-12-171057/`.

An Android debug APK also compiled successfully with
`flutter build apk --debug --no-pub`. Android's `aapt dump badging` verified:
package `org.topository.bonamangxo`, label `BonaManĝo`, minimum API 31,
target/compile API 36. Generated APK:
`flutter_app/build/app/outputs/flutter-apk/app-debug.apk` (ignored build output).

These results do not qualify Android device/radio behaviour or Ditto synchronization.
