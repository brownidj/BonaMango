# Running BonaManĝo: macOS, iOS, Chrome and Windows

Updated: 12 November 2026.

The project is `/Users/david/PycharmProjects/bona_manĝo`. Open that folder alone
in PyCharm. The visible app name is **BonaManĝo**; ASCII package/executable names
are `bona_mangxo`, `bona_mangxo_app` and, on macOS, `BonaMangxo.app`.
The native app ID is `org.topository.bonamangxo`.

All shell examples below use **zsh on the Mac**. The Windows section describes
native Windows tools and executable arguments without requiring a PowerShell
script. Run commands sequentially with `&&`; `&` starts concurrent work.

## What each platform needs

| Platform | Catalogue connection | Current verification |
|---|---|---|
| macOS app | Python service on the same Mac, port 8776 | Debug build and code signature verified |
| Chrome on a computer | Python service on that computer, port 8776 | Web release compilation and assets verified; browser interaction remains a manual check |
| iOS app | Packaged starting data plus local SQLite; optional sync to the paired Mac | Two native iOS simulator integration tests passed; this app identity still needs physical-device QA |
| Windows app | Python service on the Windows computer, port 8776 | Windows runner/icon/configuration included; Windows compilation and device behaviour are unverified |

Desktop and Chrome do not currently have the mobile offline database. Keep their
Python service running. Mobile supports offline browsing, adding, editing and
reviewing; enhanced OpenAI details discovery is unavailable on mobile.
Maps, websites and telephone actions use the operating system's available apps.

## Setup and data

The existing local checkout has its own Python environment and restaurant database.
From the project root, check your development tools:

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo'
flutter doctor -v
flutter devices
```

If Flutter is not on PATH, this Mac's SDK can be added for the terminal session:

```zsh
export PATH="/Users/david/development/flutter/bin:$PATH"
```

A fresh Git checkout does **not** include the virtual environment, researched
SQLite databases, pairing key, generated starting catalogue or build products.
Only for a fresh checkout or missing environment:

```zsh
python3 -m venv .venv
.venv/bin/python -m pip install -e .
```

If the database is missing, either restore your own backed-up
`data/restaurants.sqlite3`, or create provisional records from the included source:

```zsh
.venv/bin/python main.py import-local
```

The latter is an offline import, not the full researched catalogue. Do not use it
to replace an existing database. City completion can fall back to manual entry
without the optional local `data/cities.sqlite3` index. Browsing, manual editing
and these tests do not require an OpenAI API key.

## Run all automated tests on the Mac

Start an iOS simulator using Xcode's device interface first. Then:

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo'
./scripts/run_tests.zsh --all
```

This runs all Python tests (including real HTTP/SQLite integration), dependency
resolution, direct Dart analysis, all Flutter unit/widget/golden tests with
coverage, and all native tests in `flutter_app/integration_test/`. It selects a
booted iOS simulator; if none is booted, it fails rather than skipping tests.
Choose a specific target with `--all --device DEVICE_ID`.

The latest complete run passed **101 Python, 71 Flutter and 2 native iOS tests**,
with no analysis issues. The native tests use isolated data and fake transport;
they are not a physical Wi-Fi, Maps or browser test. Logs are in `data/logs/`.

The runner uses `dart analyze` because this installed Flutter version's
`flutter analyze` wrapper fails with the Unicode project path. A normal clean
is unnecessary. If needed, run `flutter clean` from `flutter_app` before testing;
`flutter clear` is not a valid command. Do not update golden references merely
to silence an unexpected failure.

`--all --builds` additionally compiles web/macOS/iOS release packages and checks
assets. Signed iOS builds require the appropriate Apple signing setup. Manual
checks and Windows-native builds remain separate; see [Testing](TESTING.md).

## macOS

Start the catalogue service in terminal 1, from the project root:

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo'
.venv/bin/python restaurant_server.py
```

It serves `http://127.0.0.1:8776/api/restaurants` and reads
`data/restaurants.sqlite3` relative to the project root. Keep the terminal running.
A compatible paired LAN service already running on port 8776 can also serve the
local desktop app; avoid unnecessarily switching that service out of LAN mode.

In terminal 2, test and then launch:

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo'
./scripts/run_tests.zsh --all &&
  (cd flutter_app && flutter run -d macos)
```

For a launch without repeating the completed test run:

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo/flutter_app'
flutter pub get && flutter run -d macos
```

Build a standalone release application from `flutter_app`:

```zsh
flutter build macos --release &&
  open 'build/macos/Build/Products/Release/BonaMangxo.app'
```

The app's visible name remains BonaManĝo. The ASCII bundle/executable filename
avoids the Unicode codesigning problem encountered during setup. A desktop
build still needs Python running; it does not bundle the backend or database.
The current brighter mango source assets require rebuilding an older installed
app before its Dock/app-switcher icon changes.

## Chrome

Install Chrome and keep terminal 1's local Python service running as above.
In terminal 2:

```zsh
cd '/Users/david/PycharmProjects/bona_manĝo/flutter_app'
flutter pub get && flutter run -d chrome --web-port=8080
```

Flutter opens the interface at `http://localhost:8080`. Port 8080 is the UI;
port 8776 is its catalogue API. A browser on another computer cannot use your
Mac's `127.0.0.1`; this recipe runs both services on the same computer.
Flutter documents [Chrome/Edge development setup](https://docs.flutter.dev/platform-integration/web/setup).

For a compiled web preview, build from `flutter_app`:

```zsh
flutter build web --release
```

Then serve it in another terminal from the project root, while keeping the API
service running:

```zsh
.venv/bin/python -m http.server 8080 --bind 127.0.0.1 --directory flutter_app/build/web
```

Open `http://localhost:8080`. Do not open `index.html` directly from Finder.

## iOS: simulator and development phone

The iOS runner already exists. **Do not run `flutter create` to generate it.**
Use a Mac with Xcode, an installed simulator runtime, and the Flutter SDK.
For a physical development phone, configure signing for
`org.topository.bonamangxo`, trust the Mac, unlock the phone and enable Developer
Mode as required by [Flutter's iOS setup](https://docs.flutter.dev/platform-integration/ios/setup).

List targets from `flutter_app` using `flutter devices`. From the project root,
replace `SIMULATOR_ID` with an actual simulator ID:

```zsh
./scripts/run_mobile.zsh -d SIMULATOR_ID --debug
```

The explicit debug mode is needed for the simulator. For a connected physical
phone, replace `PHONE_ID` with its actual ID:

```zsh
./scripts/run_mobile.zsh -d PHONE_ID
```

The phone launcher defaults to release so the installed app can reopen without
Flutter's debugger. It prepares the packaged catalogue, starts the Mac service
in paired LAN mode, and supplies the private local owner configuration to this
personal development build. Allow Local Network access when prompted.

No source change or extra Maps/Safari/telephone entitlement is needed merely to
launch those OS handlers; verify the actions on a physical device. A debugger's
VM-service timeout and catalogue synchronization are different connections.

## iOS: private TestFlight distribution and sync

Before first distribution of this app identity, register
`org.topository.bonamangxo` and create its matching App Store Connect record.
The renamed local project does not reuse another app's store record or pairing.

Build a TestFlight IPA after tests pass, choosing a build number greater than
any already uploaded for this app/version:

```zsh
./scripts/run_tests.zsh --all &&
  ./scripts/build_testflight.zsh --build-name 0.1.0 --build-number 1
```

Here `1` is only a first-upload example. The resulting stable path is
`build/ios/ipa/bona_mangxo_app.ipa` **under the project root**; a successful new
export overwrites the previous IPA there. Upload manually with Transporter.
See [TestFlight and Transporter](TESTFLIGHT_AND_TRANSPORTER.md) for the workflow;
historical build numbers in that document are not this app's upload history.

The shared build includes an initial catalogue and a public Mac server address,
**not** the private pairing key. A new installation can work immediately offline.
On the Mac's network, pair an invited phone once. On the Mac:

```zsh
.venv/bin/python scripts/prepare_mobile.py
./scripts/copy_pairing_key.zsh
```

On the phone, tap the sync status below the sort controls, choose **Pair with
Mac**, and paste the complete key. Use **Paste key** and **Show key** if needed;
the server URL is not the key. Keep the key private. Press **Sync now** to verify.
The key is stored in the phone's Keychain for future connections.

Keep the Mac awake, the service running and both devices on the same private
network. Idle checks run every 15 seconds after at least 5 seconds without
interaction, so a pending edit normally starts syncing after 5–20 seconds while
the app is in the foreground. Returning to the Mac network triggers a separate
2-second debounce. Clean clients do not continuously poll.

Sync and list refresh are deferred while an edit/review flow is open, including
nested Edit details. Saved changes become eligible when the flow closes; Cancel
does not save or initiate sync. The sync modal closes after a successful sync
with no pending changes/conflicts, and stays open on an error or conflict.
See [Offline packaging and synchronization](PACKAGED_CATALOGUE_AND_SYNC.md).

## Windows

Use a native Windows development machine. Install Python 3.11+, Git, the Flutter
SDK, and **Visual Studio with Desktop development with C++**. Visual Studio Code
alone does not provide that native compiler workload. Resolve Windows/Visual
Studio errors from `flutter doctor -v`; `flutter devices` must list Windows.
See [Flutter's Windows setup](https://docs.flutter.dev/platform-integration/windows/setup).
A Windows desktop build must be produced using its Windows toolchain, not this
Mac's build commands.

Copy or clone the source project into a local Windows folder and open that
folder alone in PyCharm. Do not copy the Mac `.venv`, build-cache symlink or
compiled Mac app. Use PyCharm's interpreter setup to create a local `.venv`
with the Windows Python executable. Its interpreter is
`.venv\Scripts\python.exe`, rather than the Mac's `.venv/bin/python`.

The following are native executable/argument pairs, usable through IDE run
configurations or your Windows terminal; they are not zsh scripts:

| Working directory | Executable | Arguments | Purpose |
|---|---|---|---|
| Project root | `.venv\Scripts\python.exe` | `-m pip install -e .` | Install backend dependencies |
| Project root | `.venv\Scripts\python.exe` | `main.py import-local` | Create provisional data only if a database is missing |
| Project root | `.venv\Scripts\python.exe` | `restaurant_server.py` | Start the local API on port 8776 |
| `flutter_app` | Flutter SDK's `flutter.bat` | `pub get` | Resolve Flutter packages |
| `flutter_app` | Flutter SDK's `dart.bat` | `analyze` | Static analysis |
| Project root | `.venv\Scripts\python.exe` | `-m unittest discover -s tests -v` | All Python/HTTP tests |
| `flutter_app` | Flutter SDK's `flutter.bat` | `test --coverage` | All Flutter unit/widget/golden tests |
| `flutter_app` | Flutter SDK's `flutter.bat` | `run -d windows` | Launch the Windows desktop app |
| `flutter_app` | Flutter SDK's `flutter.bat` | `run -d chrome --web-port=8080` | Launch Chrome on Windows |
| `flutter_app` | Flutter SDK's `flutter.bat` | `build windows --release` | Build the Windows release |

Keep the backend running in a separate configuration/terminal. Restore a trusted
copy of `data/restaurants.sqlite3` for the full researched catalogue; Git does
not include it. Desktop requests use `http://127.0.0.1:8776`. The Windows app does
not currently provide mobile-style offline storage or pairing.

The typical x64 release is under
`flutter_app\build\windows\x64\runner\Release\bona_mangxo_app.exe`; keep the
whole release directory with its DLLs and `data` folder, not just the executable.
The Python backend and database still need separate setup on the recipient's PC.
See [Flutter's Windows build guidance](https://docs.flutter.dev/platform-integration/windows/building).

The zsh runner's `--all` auto-selection and Apple build helpers are Mac-specific.
Run the Windows host checks above sequentially, and run native iOS integration on
the Mac. Cross-platform golden captures may differ on Windows; investigate a
failure rather than blindly replacing the reviewed references. Windows builds,
phone/browser handlers and packaged installation have not been verified here.

## Stop and troubleshoot

Press `q` or Ctrl+C in the Flutter launch terminal to stop the UI. Stop a manually
started backend with Ctrl+C. The background paired service started by the mobile
helper remains running; its log is `data/logs/mobile_service.log`.

| Problem | Action |
|---|---|
| Missing desktop/Chrome catalogue | Start Python; check `http://127.0.0.1:8776/api/restaurants` on that computer |
| Missing database after cloning | Restore your private backup, or use the provisional offline import only for a new database |
| Pairing mismatch | Paste the actual key, not the URL; ensure the updated paired service is running |
| Phone cannot reach Mac | Check Local Network permission, same network, Mac awake, firewall and guest-network isolation |
| Address starts with HTTPS | The local service uses `http://`; it is not configured for TLS |
| Wrong port occupied | Only a verified older service for this project/database is replaced; unrelated listeners are left alone |
| Analyzer crashes on the Unicode path | Use the test runner/direct `dart analyze` |
| Old installed icon | Rebuild/reinstall; editing source assets does not modify installed binaries |
| Missing Windows compiler | Install/repair Visual Studio's Desktop development with C++ workload |

No internet exposure or public hosting is configured by these instructions.
