# FLETEGO — Mobile release checklist

**Status:** Hardening in progress (Phase 14). Not ready for store submission until items below are completed.

Bundle ID: `com.fletego.app`  
App name: FLETEGO  
Subtitle / branding: by Pick&Truck

---

## Shared

- [x] Production Supabase project + RLS reviewed (Phase 14 migration applied)
- [ ] Privacy policy URL → ver `apps/admin/docs/LEGAL.md` (`/privacy` en Vercel)  
- [ ] Terms of service URL → `/terms` en el mismo deploy  
- [ ] Support contact  
- [ ] App icon & splash finalized  
- [ ] Screenshots (es-BO / es)  
- [ ] Crash reporting configured (`CrashReportingService` → vendor)  
- [ ] Analytics configured  
- [ ] No demo mode / mock repos in release builds  
- [ ] Location / camera / photos / notifications permission copy reviewed  
- [x] Secrets **not** bundled as Flutter assets (use `--dart-define-from-file`)  
- [ ] Release obfuscation: `flutter build apk --obfuscate --split-debug-info=build/debug-info`  

### Build with secrets (never commit keys)

```bash
cd apps/mobile
# .env is gitignored — used only as dart-define source, not as an asset
flutter build appbundle --release --dart-define-from-file=.env
# or
flutter build ipa --release --dart-define-from-file=.env \
  --obfuscate --split-debug-info=build/debug-info
```

Local Chrome:

```bash
chmod +x scripts/run_chrome.sh
./scripts/run_chrome.sh
```

---

## iOS

- [ ] Apple Developer account & App ID  
- [ ] Certificates & provisioning profiles  
- [ ] `Info.plist` usage descriptions (location, camera, photos, notifications)  
- [ ] Background modes only if justified  
- [ ] App Store Connect listing  
- [ ] TestFlight internal build  

---

## Android

- [ ] Play Console app  
- [ ] Upload key / Play App Signing (do **not** ship with debug signing)  
- [x] `INTERNET` in main `AndroidManifest`  
- [ ] Location / camera permissions when plugins land  
- [ ] Target / compile SDK per Play policy  
- [ ] Data safety form  
- [ ] Internal testing track  

---

## Storage

Private Supabase Storage buckets + RLS for POD/docs are **deferred** until file upload ships (paths are string placeholders today).

---

## Do not claim

Do not state the app is “production published” until signing, privacy policy, store metadata, and platform requirements are actually configured.

---

*Last updated: Phase 14 — 2026-08-17*
