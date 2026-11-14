# Phase 0: inquiry for Ditto

**Draft only — not sent.** Review the description and send it through your Ditto
Portal support channel or to `support@ditto.com`. No SDK credentials, personal
contact details, catalogue records or attachments are included.

Subject: Free-tier eligibility for a private, local-only Mac/iPhone/Android Ditto application

Hello Ditto team,

I am evaluating Ditto for BonaManĝo, a privately distributed restaurant-catalogue
application. Initially it would use a native SDK peer running persistently on my
Apple Silicon Mac mini and a Flutter app on my iPhone. Trusted invited iPhone
users may be added through TestFlight later. There is one owner/administrator.
We also plan Android support, with Android 12 (API 31) as the minimum and
Android 16 (API 36) as the target.

The first release should synchronize saved edits over the local LAN and over
Bluetooth LE when devices are nearby but not on the same Wi-Fi. Restaurant data
must not sync to Ditto Cloud or other internet destinations in this release.
Internet synchronization would be a separate later phase. Chrome would continue
through our local application API, not join the mesh directly.

Could you please confirm:

1. Does the Free offering permit this native LAN/BLE setup for continuing private
   production use, TestFlight and private Android distribution, not just evaluation? Are offline
   mesh rights included, or is a separate paid agreement required?
2. Can you issue an offline-only production licence for Shared Key / Small Peers
   Only operation at zero cost? Please distinguish licence entitlement from the
   shared cryptographic private key and from a cloud development token.
3. Does such a licence require initial internet activation or periodic internet
   renewal/check-in? What is its expiry period, how is it renewed, and what
   happens to local reads, writes and peer sync if it expires?
4. Is the persistent Mac SDK peer included in those rights, without licensing
   the full self-managed Ditto Server? What device, data, distribution and usage
   limits apply, including when an invited phone is added?
5. Are Ditto Flutter 5.2.0 for iOS/Android and Ditto Swift 5.2.0 for the Mac a supported
   interoperable pair? Our machine has ARM64 macOS 27.0.1, Flutter 3.47.1,
   Dart 3.13.1, Xcode 27.2 and Swift compiler 6.4.2; deployment targets are
   iOS 15, macOS 12 and Android 12. Please confirm the supported Apple packaging route.
6. Your current Flutter compatibility guide and package metadata list desktop
   platforms, but the versioned README still says macOS/Windows are planned.
   What is the production support status for this release, including Mac BLE? Please confirm LAN/BLE interoperability for iPhone–Mac,
   Android–Mac and iPhone–Android, including hardware, permission and background
   limitations.
7. Please confirm the supported encrypted offline initialization sequence and
   whether first enrollment can work without a connection to Ditto's servers.

Please advise if any requirement above is incompatible with the Free offering
before we migrate existing data. We are not requesting that a paid subscription
or trial contract be activated.

Thank you.
