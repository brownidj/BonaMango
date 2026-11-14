# Apple local and peer-to-peer sync alternatives

Researched: 14 November 2026. This is an assessment, not an implemented or
hardware-qualified replacement. Ditto remains on hold because production offline
licensing is paid. No dependency or data migration is introduced here.

Decision on 14 November 2026: proceed with LAN and direct Apple peer-to-peer
Wi-Fi; defer Bluetooth/BLE. See the [current implementation plan](APPLE_LOCAL_SYNC_IMPLEMENTATION_PLAN.md).

## Revised minimum

Apple devices must exchange saved changes on a reachable LAN, or directly when
there is no common LAN. Internet access and an access point must not be required
for the direct mode. Direct peer-to-peer Wi-Fi meets this requirement; Bluetooth
LE specifically is no longer a minimum requirement. Radios must remain enabled.
Android remains supported by the existing app/HTTP route; Apple proprietary
peer-to-peer Wi-Fi does not establish Android interoperability.

## Candidate comparison

| Candidate | Assessment for this app |
|---|---|
| Apple Network framework with Bonjour and peer-to-peer Wi-Fi enabled | Recommended transport proof of concept. Retain current database, outbox and owner authority. Native Swift bridge needed for Flutter. |
| Multipeer Connectivity | Previously convenient, but Apple now deprecates it and recommends migration to Network framework. Avoid starting a new implementation on it. |
| Core Bluetooth with our own BLE protocol | Additional candidate if BLE-only operation becomes necessary. We would own discovery, framing, chunking, retry, authentication and sync semantics. More implementation work than the recommended IP transport. |
| Automerge plus a native transport | Offers transport-independent document synchronization, not radio discovery itself. Consider only if multi-writer automatic merging is a separate requirement; adoption changes the data model and conflict policy. |

These are architecture choices, not equivalent turnkey database products.
Native OS APIs do not introduce Ditto's separate commercial sync-token dependency;
Apple's ordinary development/distribution arrangements still apply.

Sources: [Network migration guidance](https://developer.apple.com/documentation/technotes/tn3213-moving-from-multipeer-connectivity-to-network-framework),
[API selection guidance](https://developer.apple.com/documentation/technotes/tn3151-choosing-the-right-networking-api),
[Core Bluetooth](https://developer.apple.com/documentation/corebluetooth),
[Automerge concepts](https://automerge.org/docs/reference/concepts/).

## Proposed application design

This is our proposed implementation, not functionality supplied automatically by
Apple's transport framework:

- Keep the Mac as the authoritative coordinator initially. A native Swift helper
  accepts authenticated connections and passes operations to the existing host
  validation/audit path over private local IPC. A Flutter platform-channel adapter
  connects iOS/macOS clients through the existing transport boundary.
- Discover the paired host through Bonjour; never trust a service name alone.
  Use authenticated TLS and an enrollment flow that pins device/host identities.
  Keep credentials in Keychain and enforce the sole-owner policy in the host.
- Keep pending edits and conflict history in local SQLite. Sync only committed
  changes, respect the editing barrier, and treat host acceptance as completion.
  Add durable operation receipts for safe reconnect/retry; do not replace this
  with a full-database last-writer-wins copy.
- Enable direct Wi-Fi for browsing/listening/connecting when needed. Use a bounded
  discovery/retry lifecycle to avoid continuous power-intensive browsing. Explicit
  reconnect after losing a connection is part of our implementation.
- Use older `NWBrowser`, `NWListener`, `NWConnection` APIs to preserve the current
  iOS 15/macOS 12 deployment goals, subject to a compile and physical-device spike.
  The newer Swift API syntax in Apple's examples is not a reason to raise minimums.

Apple documents the older APIs as capable of implementing the migration approach.
[Peer-to-peer opt-in](https://developer.apple.com/documentation/network/nwparameters/includepeertopeer)
enables peer link technologies; it does not supply database replication.

Initial topology is Mac–iPhone/iPad. If two invited phones must exchange changes
while the Mac is absent, define a separate authenticated relay/replication model,
with stable operation IDs and host receipts so relayed work is not reported as
accepted by the owner prematurely. The framework allows either topology; our
existing Mac-authoritative protocol does not yet implement phone relaying.

## Proof before migration

1. Build an isolated Swift transport with fictional data; authenticate one Mac
   and one physical iPhone. Preserve the working HTTP implementation.
2. Prove encrypted two-way LAN exchange with internet traffic blocked.
3. Disconnect the devices from the access point while leaving radios enabled;
   prove Bonjour discovery and direct transfer. Record the actual network path.
4. Test sleep/wake, foreground/background, denied permissions, wrong identity,
   interrupted transfers, reconnect and battery behaviour. Do not promise
   continuous iOS background sync.
5. Integrate the durable application operations and run conflict/idempotency,
   offline-restart and editing-barrier tests over the new transport.
6. Qualify a second physical phone before claiming phone-to-phone operation.

Simulator tests cannot establish radio behaviour. No automatic mesh relaying or
Android peer interoperability is claimed by this assessment. Chrome retains the
existing local application API. Internet synchronization remains a later phase.
