# Ditto Phase 0: licence, authentication and SDK findings

Date: **12 November 2026**  
Project: **BonaManĝo**  
Status: **Vendor response reviewed 14 November 2026: free offline-only production use is unavailable. Commercial gate failed under the zero-cost requirement; Phase 1 must not start.**

## Decision

Ditto's response supplied by David confirms that this architecture requires a
paid production agreement and a Ditto-issued offline-only licence. Private
TestFlight/Android distribution does not provide an exemption. Therefore the
requested zero-cost migration cannot proceed with Ditto.

See [vendor response assessment](DITTO_VENDOR_RESPONSE.md) for the confirmed
technical route and remaining decisions. No Ditto SDK or migration is installed.
The provider-neutral preparation and existing HTTP/SQLite sync remain usable.

The research tables and checklist below retain the original 12 November
investigation context; outstanding entitlement questions are superseded by the
14 November vendor response. No free licence was issued or validated.

## Phase 0 task results

| Plan task | Result | Remaining evidence |
|---|---|---|
| Free private production/TestFlight LAN/BLE entitlement | Not established | Ditto's written or account-specific confirmation |
| Offline-only licence, expiration and renewal | No token obtained or validated | Issued licence, scope, expiry/renewal terms and outage behaviour |
| Persistent Mac SDK host entitlement | Not established | Confirm included peer-host rights; not full Ditto Server licensing |
| Exact SDK and local toolchain selection | Candidate pair identified; static checks passed | Vendor confirmation and isolated compile/link test after the gate |
| Fresh-device enrollment without internet data traffic | Not run | Licence and private test setup; then physical-phone evidence |

A successful source/metadata inspection is not a successful installed SDK,
licence activation, encrypted session or BLE test.

## 1. Licensing findings

The public Free offering specifies cloud allowances and a Ditto-hosted deployment
model. It does not explicitly establish a zero-cost entitlement for the offline
production design. Self-managed deployment is listed under Enterprise; that is
not the same product as embedding a persistent native SDK peer on the Mac.
[Pricing](https://www.ditto.com/pricing)

Ditto's authentication documentation states that Shared Key requires an
offline-only licence token, generally issued to customers with a production
agreement. No account-specific exception, free grant or renewal term was obtained.
Shared Key also gives all enrolled peers the same data-access rights; it is not
a device-level permission/revocation system.
[Authentication and Authorization](https://docs.ditto.live/key-concepts/authentication-and-authorization)

The published Flutter package's activation method independently confirms that an
offline instance must be licensed before it can sync across instances. Merely
selecting `SmallPeersOnly` does not establish activation or a commercial right.
The package contains a proprietary binary licence with redistribution conditions,
not an MIT/Apache licence; retain its notices when distributing an approved build.
[Versioned package and licence](https://pub.dev/packages/ditto_live/versions/5.2.0)

I opened the public Ditto Portal entry point. It redirected to a sign-in page;
no authenticated session or entitlement was available in this browser. No login
credentials were entered, account created, terms accepted or message sent.
[Ditto Portal](https://portal.ditto.live/)

David has now confirmed that a Ditto account exists, superseding the earlier
reply that there was no account. Account creation alone does not establish the
plan, production offline entitlement or possession of an offline licence. Those
items remain unverified; no credentials or licence token have been supplied.

This is a pending confirmation, not proof that Ditto has refused free use.

## 2. Verified local environment

Read from this Mac and project during Phase 0:

| Item | Observed value | Assessment |
|---|---|---|
| Machine architecture | `arm64` | Matches the Apple Silicon native route |
| macOS | 27.0.1 | Above the published macOS 12 minimum |
| Flutter | 3.47.1 stable | Above declared minimum; actual integration still needs compilation |
| Dart | 3.13.1 | Within package constraint `>=3.5.4 <4.0.0` |
| Xcode | 27.2, build 27B52 | Above documented v5.1+ requirement of Xcode 26.2 |
| Swift compiler | 6.4.2 | Above documented v5.1+ requirement of Swift 6.2 |
| Existing project Swift language setting | 5.0 | Not the compiler version; do not change automatically |
| Existing iOS deployment target | 15.0 | Matches conservative documented SDK minimum |
| Existing macOS deployment target | 12.0 | Matches documented SDK minimum |
| Python | 3.14.0 | Current backend; not used as the BLE SDK host in the proposed design |

The toolchain is suitable for a **candidate build**, not proof of compatibility
with these newer OS/compiler versions. No compatibility promise is inferred from
version arithmetic alone.
[Flutter compatibility](https://docs.ditto.live/sdk/latest/compatibility/flutter),
[Swift compatibility](https://docs.ditto.live/sdk/latest/compatibility/swift)

## 3. Exact candidate SDK pair

Use these exact versions for the eventual isolated experiment, not floating
`latest`, a prerelease or an unbounded version range:

| Component | Candidate | Evidence |
|---|---|---|
| Flutter iOS client | `ditto_live: 5.2.0` | Current pub.dev API stable metadata, published 27 October 2026 |
| Native macOS host | `DittoSwiftPackage` tag `5.2.0`, product `DittoSwift` | Versioned package manifest points to `DittoSwift/5.2.0` |
| Shared protocol family | 5.2.0 candidates on both sides | Exact pair still needs vendor/interoperability confirmation |

The live pub.dev API reported 5.2.0 even though earlier cached search results
showed 5.1.0. The Flutter archive SHA-256 matched its registry metadata:

```text
c6b40d25412292ddaa299d342abb9885400dd444c6c472121ccf10fdfe809442
```

The Swift package manifest's binary checksum is:

```text
a26ba4c060972574c74a578d909b6223d6b43d445a8d3697fa0b5c493f458b4f
```

Only the Swift manifest was inspected; its binary was **not** downloaded or
checksum-verified. Do not confuse its declared checksum with a completed check.
[Flutter package registry](https://pub.dev/api/packages/ditto_live),
[versioned Swift manifest](https://raw.githubusercontent.com/getditto/DittoSwiftPackage/5.2.0/Package.swift)

The Flutter archive contains macOS/iOS FFI declarations and Windows build support.
Its Apple podspecs identify 5.2.0 native dependencies and explicitly exclude Intel
Apple targets. The Windows CMake file selects an x86-64 DLL. The package README
still labels desktop support “Planned”, in conflict with its platform metadata
and the current compatibility guide. Therefore:

- Use the native Swift SDK for the initial Mac radio host.
- Treat Flutter desktop support as **declared, not production-verified**.
- Do not promise Intel Mac support; test on this ARM64 Mac and ARM64 simulator.
- Obtain confirmation of the supported Flutter 5.2.0 Apple build route, including
  Swift Package Manager versus CocoaPods with the current Xcode configuration.
- Do not silently switch SDK versions or rewrite the existing Apple project to
  make an unsupported integration appear to pass.

[Versioned Flutter distribution](https://pub.dev/packages/ditto_live/versions/5.2.0)

## 4. Offline initialization and encryption requirements

Inspection of the **5.2.0 public source archive**, without installing it, found:

- `DittoConfigConnectSmallPeersOnly(privateKey: ...)` is the local-only
  configuration type. Its source documentation says that omitting `privateKey`
  means no in-transit encryption. A local-only mode name is not a security control.
- `setOfflineOnlyLicenseToken(...)` activates an offline instance for cross-peer
  sync; `isActivated` reports activation state.
- The configuration type's `toString()` includes the private key value. Never log
  that object or include it in diagnostic screenshots/support bundles.

These findings must become integration requirements: require a correctly formed
shared private key, obtain an appropriate offline licence, confirm activation,
explicitly forbid cloud/server destinations, then start only approved local
transports. Verify that sequence against the pinned Swift API too. Never fall
back to an empty key, unencrypted mode or Playground authentication on failure.
[Inspected package](https://pub.dev/packages/ditto_live/versions/5.2.0)

The current 43-character HTTP pairing token is **not** automatically the Ditto
private key, licence token or host-signing key. Keep those credentials distinct.
Do not generate or distribute real group credentials before selecting the
approved enrollment model. Persist secrets using Keychain and private ignored
configuration; publish only placeholders in code and documentation.

Online authentication is a separate architecture: cached certificates can expire
and require renewal. Disabling catalogue cloud transports does not remove that
dependency. It has not been selected as a substitute for the requested local-only
phase. [Authentication model](https://docs.ditto.live/key-concepts/authentication-and-authorization)

## 5. Evidence retained locally

Public metadata and selected unmodified package text were saved under:

```text
data/logs/ditto-phase0/
```

This ignored directory includes the Flutter registry metadata, package manifest,
licence, Apple podspecs, Windows CMake file and relevant config/activation source.
No downloaded SDK source was executed or added to the app dependencies. The
source archive was read in memory; native libraries were not installed.

Checks performed: environment/version inspection, project target inspection,
registry/archive digest validation and static SDK API/package inspection.

Not performed: dependency resolution with Ditto, native SDK compilation/linking,
licence activation, peer discovery, BLE session, offline phone enrollment or any
live restaurant-data migration. No app regression suite was rerun because the
application code and dependencies are unchanged.

## 6. Questions to resolve with Ditto

A ready-to-send inquiry is in
[DITTO_PHASE_0_VENDOR_INQUIRY.md](DITTO_PHASE_0_VENDOR_INQUIRY.md). It requests:

1. Zero-cost entitlement for a private native Mac/iPhone LAN/BLE application,
   including limited TestFlight distribution; clarify whether evaluation and
   continuing production rights differ.
2. An offline-only production licence, its expiration/renewal requirements, any
   initial/periodic internet check, and what happens to local reads and sync at expiry.
3. Rights to run an always-on Mac SDK peer, distinct from self-managed Ditto Server.
4. Limits on peers, data and distribution, plus any unexpected cost requirement.
5. Confirmation of the exact 5.2.0 Swift/Flutter pair, supported desktop status,
   Apple Silicon/Xcode build route and encrypted offline configuration.

The inquiry assumes only the currently identified Mac mini and owner's iPhone.
It asks how limits apply when an invited phone is added; it does not invent a
fleet size or commit David to a contract.

## 7. Exit checklist

- [x] Inspect current code, project targets and local toolchain.
- [x] Select and document an exact candidate SDK pair from live primary metadata.
- [x] Inspect the offline activation API, encryption default and licence notices.
- [x] Prepare a concrete vendor inquiry without transmitting it.
- [ ] Receive account-specific/written confirmation of zero-cost production rights.
- [ ] Obtain and securely validate the offline licence and renewal conditions.
- [ ] Confirm exact SDK interoperability and Apple packaging route.
- [ ] Record a fresh-device enrollment result with internet data traffic blocked.
- [ ] Mark Phase 0 passed and proceed to Phase 1.

**Next decision:** retain the zero-cost requirement and evaluate another provider,
or explicitly choose to seek a paid Ditto agreement. No contract or paid service
has been activated. Never paste credentials into this document or the chat.
