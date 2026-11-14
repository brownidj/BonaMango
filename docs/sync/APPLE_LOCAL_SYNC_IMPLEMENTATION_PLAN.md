# Apple local synchronization implementation plan

Decision date: 14 November 2026. Status: approved direction; documentation only.
No native networking helper, new pairing flow or database migration has been
implemented by this plan. The existing HTTP/SQLite sync remains active.

## Scope and transport decision

Use Apple's Network framework with Bonjour discovery for:

1. Mac–iPhone/iPad sync on a reachable local network, including Ethernet/Wi-Fi.
2. Direct Apple peer-to-peer Wi-Fi when devices do not share a local network.

Bluetooth/BLE transport is deferred. Do not implement a Core Bluetooth adapter,
BLE message protocol, Bluetooth-specific app permissions or Bluetooth background
modes in this phase. Direct Wi-Fi must be demonstrated on physical devices; it
must not require a router, hotspot or internet service.

This is a choice of application transport, not a promise that every Bluetooth
radio can be switched off: Apple manages discovery and peer links. Leave system
radios available during initial qualification and record the configurations that
actually work. Do not label this as BLE synchronization or advertise Bluetooth
support. If fully disabling Bluetooth becomes a requirement, test it separately.

The first topology is one authoritative Mac mini with invited iPhones/iPads.
There is one owner/administrator. Invited devices may submit edits and reviews;
being invited does not grant owner/administrative authority. Phone-to-phone
relay without the Mac, multi-hop mesh, Android direct peer links and internet
sync are later work. Android's current local database/HTTP path and Chrome's
existing application API remain available; this plan does not remove them.

## Architecture

These are application design decisions rather than automatic Network framework
features:

- Keep the host SQLite catalogue, validation, review audit and conflict policy.
  Keep each mobile SQLite snapshot/outbox, source evidence and conflict history.
- Add a native Swift host helper using `NWListener`. Run it under the logged-in
  owner's account, with an eventual LaunchAgent for login startup. Do not assume
  a logged-out daemon or a sleeping Mac can provide reliable direct Wi-Fi.
- Use `NWBrowser` and `NWConnection` in a small native Flutter bridge on Apple
  clients, behind the existing `CatalogueTransport` interface. The host helper
  passes operations to the Python host through private local IPC; it does not
  become a second independent database writer.
- Preserve iOS 15/macOS 12 deployment goals using the older NW APIs, subject to
  compilation and device qualification. Do not copy newer API syntax that raises
  those minimums unintentionally.
- Advertise a dedicated Bonjour service and opt into peer-to-peer interfaces for
  discovery, listening and connections. Deduplicate connections by enrolled
  device identity. Bound browsing and retry time; stop idle work and use backoff.
  Network path changes may require reconnect; automatic failover is a test target,
  not an assumed framework guarantee.
- Frame versioned, size-bounded application messages over an authenticated TLS
  connection. Apply message and decompression limits, chunk large snapshots and
  validate complete snapshots before publishing them locally.

The service name identifies a candidate host, never authenticates it. Keep
private IPC bound to an owner-controlled Unix socket or equivalently restricted
endpoint, with OS access restrictions and explicit authentication as appropriate.
Do not expose privileged IPC through a general LAN listener.

## Enrollment and security

Design a short-lived invitation approved by the owner. Pin the Mac's identity
and enroll a distinct device public key; retain private credentials in Keychain.
Use certificate-authenticated TLS and a maintained identity/certificate library
rather than inventing encryption. A development self-signed certificate is not
trusted merely because the connection is encrypted. Never disable verification
or embed one universal private identity in every distributed app.

Specify certificate creation, renewal, lost-device revocation and re-enrollment
before production. Revoking a device must reject future connections on both LAN
and direct Wi-Fi. Do not put secrets in Bonjour TXT records, logs or bundled
catalogue assets. The existing HTTP pairing credential is not automatically a
TLS identity; preserve it for fallback while the new enrollment is qualified.

Add Bonjour declarations and local-network usage descriptions and verify macOS
sandbox incoming/outgoing network entitlements. Record OS-version-specific
permission behaviour. No new entitlement or minimum OS claim is considered
verified merely because a simulator builds.

## Saved changes and durable acceptance

- Draft typing causes no network writes. Preserve the nested edit/review barrier.
  Save or a confirmed review action durably queues a change; upload becomes
  eligible after the editing flow closes. Cancel creates no change or sync.
- Give each command a stable unique operation ID and expected record revision.
  A retry after a lost response must not duplicate an addition, review or audit.
- Commit host record changes, audit history and operation receipts in the same
  SQLite transaction. Replaying an accepted ID returns its existing receipt;
  reusing an ID with different content is rejected.
- Device delivery is not host acceptance. Remove pending work only after a
  validated host receipt is durably stored locally. Keep pending edits after
  timeouts, disconnects or storage failures.
- Download using catalogue versions/cursors. A clean device does not continually
  exchange full snapshots. Check remote changes on connection/resume or explicit
  refresh, with bounded idle work. A durable journal/cursor design must capture
  deletions and every host write path, including research/import and legacy HTTP.
- Preserve conflicting versions and allow explicit resolution. Do not replace
  the entire database or silently apply last-writer-wins. Keep temporary ID and
  dependent revision remapping correct across add/edit/review/delete chains.

## Implementation phases

### A — Isolated connection proof

Create a separate Swift prototype using fictional data and test identities.
Compile for the intended deployment minimums, then test one physical iPhone with
this Mac mini. Demonstrate encrypted two-way LAN and direct Wi-Fi exchange with
internet blocked. Explicitly disconnect from the access point for direct mode;
record discovery and connection path evidence. Preserve current app data.

Exit: device/OS versions, configuration, logs and repeatable success for both
modes. A simulator or same-router test alone does not pass this phase.

### B — Durable host command protocol

Define versioned messages, IDs, revisions, receipts, errors, pagination and
limits. Implement idempotent host processing and change tracking behind existing
validation/audit services. Test interruptions before/after every durable commit,
including lost acknowledgement and host restart. Keep fallback HTTP running.

Exit: no duplicate changes or audit entries; all writers/deletions appear in
incremental downloads; existing Python and persistence suites pass.

### C — Apple client adapter and enrollment

Add the native Flutter bridge, secure enrollment and transport selection. Retain
local offline access even when permissions, enrollment or connection fail. Show
connecting, pending, conflict and accepted states accurately. Add safe recovery
from cancellation, untrusted hosts and unexpected responses.

Exit: automated transport contract/UI tests and physical end-to-end saved-edit,
review, conflict and reconnect checks. No edits change underneath an open modal.

### D — Resident host and lifecycle qualification

Add owner-login startup, bounded retries, connection cleanup and diagnostics
without secrets. Test Mac sleep/wake and phone foreground/background transitions.
Phones should be open/foreground for the first supported reliable sync workflow;
continuous suspended/terminated iOS sync is not promised. Keep the Mac awake.

Exit: hardware acceptance matrix and an owner-usable troubleshooting guide.

### E — Controlled rollout and rollback

Back up host and device data, enable the new adapter for one device, and verify
receipt/outbox consistency before broader distribution. Feature-flag rollback
must retain pending work, pairing fallback and histories without double replay.
Keep the working HTTP implementation until recovery has been demonstrated.

Phone-to-phone sync, Android peer interoperability and internet access require
separate proposals and qualification; they are not exit criteria for this phase.

## Acceptance matrix

| Scenario | Required outcome |
|---|---|
| Same LAN, no internet | Authenticated bidirectional sync with valid host receipts |
| Nearby, disconnected from access point | Direct Wi-Fi sync, no hotspot/router/cloud required |
| No reachable peer | Full local use; pending changes survive restart |
| Lost response after host save | Retry returns receipt; no duplicate record/review/audit |
| Mac changed the same record | Conflict retained; explicit user resolution |
| Editor/review open | No upload or incoming replacement of the draft |
| Permission denied or untrusted/revoked device | Clear recoverable status; no unauthorized data exchange |
| Mac sleep or phone suspended | No data loss; reconnect/resume converges when available |
| Large catalogue and Unicode | Bounded transfer and successful Android-safe local persistence |
| New adapter disabled | HTTP fallback works without discarding or replaying accepted work |

One physical iPhone plus the Mac is enough for the initial transport proof.
A second physical phone is required before claiming independent phone-to-phone
operation. Record untested cases as outstanding rather than inferring success.

## Sources and current evidence

- [Apple migration guidance](https://developer.apple.com/documentation/technotes/tn3213-moving-from-multipeer-connectivity-to-network-framework): Network architecture, security and older API equivalents.
- [Networking API selection](https://developer.apple.com/documentation/technotes/tn3151-choosing-the-right-networking-api): recommended framework and Multipeer deprecation.
- [Peer interface opt-in](https://developer.apple.com/documentation/network/nwparameters/includepeertopeer): interface setting, not a replication engine.
- [Peer interface lifecycle](https://developer.apple.com/documentation/network/nwparametersprovider/peertopeerincluded(_:)): power considerations and bounded retry.
- [Existing preparation](SYNC_PREPARATION.md): implemented store/transport boundary.
- [Alternatives assessment](APPLE_SYNC_ALTERNATIVES.md): research behind this decision.
- [Ditto vendor response](../ditto/DITTO_VENDOR_RESPONSE.md): commercial reason for changing direction.

No runtime changes or new tests were made for this documentation update. Phase A
has not started; all acceptance rows above are planned verification.
