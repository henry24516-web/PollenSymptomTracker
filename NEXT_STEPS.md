# NEXT_STEPS.md - PollenSymptomTracker

## What Was Accomplished (Without Mac)

✅ **Generated project.yml** - Complete XcodeGen configuration ready
✅ **Verified Swift code** - All 9 services, 3 view models, 7 views, 3 models reviewed for:
  - Missing imports
  - Broken references  
  - Syntax issues
  - All code looks correct and compilation-ready

✅ **Created App Store submission package**:
  - App description (1,800 chars)
  - Keywords (92 chars)
  - Privacy Policy draft
  - What's New section
  - Title variations
  - Info.plist values summary

✅ **Researched App Store requirements** for health/wellness subscription apps:
  - Clear subscription pricing requirements
  - 7+ day subscription period rule
  - Updated age rating questions (due Jan 31, 2026)
  - No HealthKit data = faster review

---

## What Requires a Mac

### 1. Generate Xcode Project
```
cd PollenSymptomTracker
xcodegen generate
```
xcodegen is a macOS tool and cannot run on Linux.

### 2. Build the Project
```
xcodebuild -project PollenSymptomTracker.xcodeproj \
  -scheme PollenSymptomTracker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```
Requires Xcode + macOS.

### 3. Create App Store Assets
- App screenshots (multiple sizes)
- App icon (1024x1024 for App Store)
- Optional: Preview video

### 4. Submit to App Store
- Upload via Xcode or Transporter
- Requires Apple Developer Account

---

## Credentials/Info Needed from Nicholas

### Required for Submission:

1. **Apple Developer Account**
   - Email associated with developer account
   - Team ID (from App Store Connect)

2. **App Store Connect**
   - App name: "Pollen Tracker"
   - Bundle ID: `com.pollenhealth.symptomtracker`
   - SKU (internal ID)

3. **Subscription Setup**
   - Create subscription product in App Store Connect
   - Product ID: `com.pollenhealth.symptomtracker.premium.monthly`
   - Price tier: £2.99 (Tier 2)
   - Provide **Test User** credentials for subscription review

4. **Privacy Policy URL**
   - Host the privacy policy (can use GitHub Pages, Notion, etc.)
   - Provide the live URL

5. **Test Account**
   - Apple ID for App Review team to test subscription flow

### Optional for Testing:

6. **Device for Testing**
   - Physical iPhone/iPad for real device testing
   - Or use Xcode Simulator (requires Mac)

7. **Push Notification Certificate** (for production alerts)
   - Requires Apple Developer account
   - Create APNs certificate in portal

---

## Quick Start (Once Mac Available)

```bash
# 1. Clone/copy project to Mac
cd PollenSymptomTracker

# 2. Generate Xcode project
xcodegen generate

# 3. Open in Xcode
open PollenSymptomTracker.xcodeproj

# 4. Select simulator & build (Cmd+B)

# 5. Upload to App Store
# Use Xcode: Product > Archive > Distribute App
# Or use Transporter app
```

---

## Notes

- The app targets iOS 16.0+ (SwiftUI)
- Uses StoreKit 2 for subscriptions
- No backend required - all data local + Open-Meteo API (free)
- Project is otherwise **complete and ready to build**
