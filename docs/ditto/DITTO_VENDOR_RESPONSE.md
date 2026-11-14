# Ditto vendor response assessment

Reviewed: 14 November 2026. Source: the support response supplied by David in
this chat. This is a summary of vendor statements, not independently reproduced
SDK/hardware test results. No licence, subscription or agreement was activated.

## Decision

The requested ongoing, offline-only production use is unavailable at zero cost.
A production agreement and Ditto-issued offline licence are required, including
for private TestFlight and Android distribution. The commercial gate therefore
fails under the current free-tier requirement. Do not migrate data or begin the
Ditto radio prototype unless that requirement is explicitly changed.

## Confirmed by the vendor

- A persistent Mac native Swift Small Peer is supported without the full Ditto
  Server product, but still needs appropriate production rights.
- Flutter 5.2.0 on iOS/Android can interoperate with Swift 5.2.0 on macOS.
- Offline licences validate locally without initial activation or periodic
  internet check-in. Expiry and renewal terms are agreement-specific. Applying
  an expired token fails; startup must isolate that error from local data access.
- iPhone–Mac, Android–Mac and iPhone–Android support LAN/BLE subject to hardware,
  permissions and actual device validation. Background operation is limited by
  each OS. The Mac must stay running and awake.
- New-device enrollment can be offline with securely provisioned database ID,
  shared private key and valid licence. Shared Key does not supply per-device
  revocation or separate owner/read-only permissions; local storage encryption
  is separate. Host authority and enrollment remain application responsibilities.
- iOS 15, macOS 12 and Android 12 minimums are acceptable. The exact local
  toolchain combination was not tested by Ditto. Swift packaging uses SPM;
  Flutter's Apple dependency uses CocoaPods for the specified SDK release.
- The vendor recommends Android AGP 8.13.2, Kotlin 2.3.21, Gradle 8.13, JDK 17
  (or supported newer), compile SDK 36 and NDK 27.0.12077973 for Ditto. This is
  recorded guidance, not an instruction to change the working non-Ditto build.
- Desktop documentation's conflicting planned/supported labels were referred
  to Ditto's SDK team. Actual production/hardware qualification remains needed.

## Work retained

The current authenticated HTTP sync, local SQLite catalogue, saved-edit barrier,
Android fixes and provider-neutral transport/store interfaces remain useful.
No pricing quote, production licence or agreed usage limits were supplied.
The next decision is whether to evaluate zero-cost alternatives or explicitly
seek a paid Ditto proposal. No alternative has yet been qualified for the full
LAN/BLE, Apple/Android and private distribution requirements.
