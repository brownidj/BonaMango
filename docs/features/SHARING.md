# Sharing restaurant details

Press the share icon immediately before the phone icon in a restaurant's actions.
It remains available when no phone number is listed. Android, iOS and macOS use
the system share sheet through `share_plus`. Choose an app or action there to
share the text. iPad/macOS popovers are anchored to the pressed button.

The text includes the restaurant name and each listed city, country, address,
cuisine, special dishes, notes, telephone number and website. Empty fields and
`not listed` placeholders are omitted. Internal IDs, revisions, review notes,
source evidence and pairing credentials are excluded. Sharing does not edit or
synchronize the restaurant. Dismissing the share sheet causes no error message.

Other platforms use the plugin's supported sharing behaviour (browser Web Share
where available, with platform fallbacks); available targets depend on the OS and
installed apps. If the platform call fails, the app shows a retry message.

Implementation: `flutter_app/lib/widgets/restaurant_share_button.dart`.
Tests cover the content, omission of internal metadata, popover origin,
cancellation, error feedback and icon position on iOS/Android layouts. The four
visual baselines include the new icon. All 79 Flutter tests and Dart analysis
passed on 13 November 2026.

Android and macOS debug builds also passed. On the Pixel 8 AVD, pressing the
first restaurant's share icon opened Android's native text share chooser with
the expected restaurant details and available app targets. The chooser was
cancelled without sending anything. iOS native share-sheet interaction remains
a device QA check.
