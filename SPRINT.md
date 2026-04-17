# Childlock iOS Ship Sprint

**Started:** 2026-03-30  
**Goal:** Ship to TestFlight with validated Screen Time lock path  
**Owner:** Kato (build) + Xavier (physical device validation)

---

## Checklist

### Phase 1: Build Infrastructure (Complete ✅)
- [x] Create entitlements files (Family Controls)
- [x] Create Xcode project with app + extension targets
- [x] Wire up app entry point
- [x] Create DeviceActivityMonitor extension
- [x] Create ShieldAction extension
- [x] Create ShieldConfiguration extension
- [x] Add SharedDefaults helper (cross-target communication)
- [x] Project file updated with all 3 extension targets
- [ ] Build for simulator — **Next: Run `./build.sh` to verify compile**

### Phase 2: Signing + Certificates (Blocked - Needs Xavier)
- [ ] Apple Developer account access
- [ ] Create Apple Distribution certificate
- [ ] Create provisioning profile (com.kopikoubou.childlock)
- [ ] Create provisioning profile (com.kopikoubou.childlock.monitor)
- [ ] Configure Xcode signing team

### Phase 3: Physical Device Validation (Blocked - Needs Device)
- [ ] Install on physical iOS device (17.0+)
- [ ] Configure Family Sharing group
- [ ] Authorize Family Controls
- [ ] Test monitor extension triggers
- [ ] Test shield activation
- [ ] Validate challenge flow

### Phase 4: TestFlight Submission
- [ ] Archive build
- [ ] Upload to App Store Connect
- [ ] Submit for TestFlight review
- [ ] Seed users

---

## Blockers

| Blocker | Owner | Status |
|---------|-------|--------|
| Apple Developer account access | Xavier | ⏳ Pending |
| Physical iOS device (17.0+) | Xavier | ⏳ Pending |
| Family Sharing group configured | Xavier | ⏳ Pending |

---

## Notes

- Extension points require **actual iOS device** (simulator doesn't support Family Controls)
- Signing requires **manual Apple Developer Portal setup** (certs + profiles)
- Once unblocked: ~4-6 hours to full validation
