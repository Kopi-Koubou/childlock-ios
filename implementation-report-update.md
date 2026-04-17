# Childlock Production-Hardening Update

Date: 2026-03-14 (GMT+8)  
Scope: Production-hardening lanes A-D only (Screen Time enforcement path, persistence, and QA evidence refresh)

## Lane A — Tokenized FamilyActivityPicker + App Group persistence

Completed:
- Replaced scoped app-name-only path with token-capable onboarding state (`selectedActivityTokenData`) and App Group persistence via `AppGroupFamilyActivitySelectionStore`.
- Added iOS FamilyControls picker integration in onboarding (`FamilyActivityPicker`) with token-data hydration and update flow.
- Upgraded `ChildProfile` monitored-app payload to a versioned envelope:
  - opaque token data (`selectionTokenData`)
  - UI summary display names
  - legacy `[String]` decode fallback retained for migration safety.

Evidence:
- New tests:
  - `ChildProfileTests`
  - `FamilyActivitySelectionStoreTests`
  - `OnboardingViewModelTests.testInitHydratesSelectionFromStore`

## Lane B — DeviceActivity/Shield extension entrypoints + lifecycle hardening

Completed:
- Hardened `ScreenTimeManager`:
  - explicit authorization gating
  - entitlement/authorization failure capture
  - monitored-selection validation/decode
  - idempotent monitor start/stop with persisted lifecycle keys
  - shared status/error updates (`monitoringStatus`, `monitoringLastError`).
- Added extension entrypoint source wiring in `ScreenTimeExtensionEntrypoints.swift`:
  - `ChildlockDeviceActivityMonitor`
  - `ChildlockShieldAction`
  - `ChildlockShieldConfiguration`
- Added parent settings lifecycle controls for lock enforcement start/stop and status feedback.

Evidence:
- `swift build` compiles all touched sources.
- `swift test` passes with new and existing tests.

## Lane C — App Group persistent state store (SwiftData-lite)

Completed:
- Replaced default app-state store from UserDefaults-only to file-backed `AppGroupFileAppStateStore`.
- Added schema-versioned container (`schemaVersion: 2`) and legacy fallback migration from prior snapshot storage.
- Kept fallback save path to UserDefaults for resilience.

Evidence:
- `AppStatePersistenceTests` now includes:
  - file-store roundtrip
  - fallback defaults migration coverage.

## Lane D — QA artifact hardening (replace seeded placeholders)

Completed:
- Replaced seeded QA artifact content with concrete build/test evidence and explicit blocker reporting.
- Created this update report for week-1 production-hardening evidence.

Updated artifact:
- `qa-results.json` now records:
  - `swift build` passed
  - `swift test` passed (25/25)
  - lane-level evidence
  - explicit physical-device entitlement blockers.

## Verification Commands

```bash
cd /Users/devl/clawd/projects/childlock
swift build
swift test
swift build --triple arm64-apple-ios17.0-simulator
```

Result:
- Build: pass
- Tests: pass (25 passed, 0 failed)
- iOS target triple build: blocked in this environment (`unable to load standard library for target 'arm64-apple-ios17.0-simulator'`)

## Remaining Blockers Before Ship

1. A signed iOS app project with real extension targets is still required (DeviceActivityMonitor, ShieldAction, ShieldConfiguration) with Family Controls entitlements.
2. End-to-end physical device validation is still required for Family Sharing + Screen Time runtime behavior (threshold trigger, shield display, defer-to-app challenge flow, shield removal after success).
3. Current execution environment cannot compile iOS target triples for this package; iOS-target compile verification must run in a full Xcode/iOS toolchain environment.
