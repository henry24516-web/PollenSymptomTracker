# PollenSymptomTracker

iOS app for tracking pollen allergy symptoms with subscription monetization.

## Project Structure

```
PollenSymptomTracker/
├── App/                    # App entry point
├── Views/                  # SwiftUI Views
│   ├── OnboardingView.swift
│   ├── PaywallView.swift
│   ├── SettingsView.swift
│   ├── PollenView.swift
│   ├── SymptomLogView.swift
│   └── TrendChartView.swift
├── ViewModels/             # ViewModels (MVVM)
├── Models/                 # Data models
├── Services/               # Business logic services
│   ├── PaymentService.swift     # StoreKit 2
│   ├── NotificationService.swift # Local notifications
│   ├── StorageService.swift     # Data persistence
│   ├── PollenAPIService.swift
│   └── AIService.swift
├── Resources/              # Assets & configs
│   ├── Assets.xcassets/
│   └── SubscriptionConfig.json
├── Tests/
│   ├── PaymentServiceTests.swift
│   ├── NotificationServiceTests.swift
│   └── StorageServiceTests.swift
└── project.yml            # XcodeGen configuration
```

## Features Included

- ✅ SwiftUI-based UI
- ✅ Onboarding flow with notification opt-in
- ✅ StoreKit 2 payment integration
- ✅ Local notifications for daily reminders
- ✅ Premium subscription management
- ✅ Data export capability
- ✅ Privacy-first design

## StoreKit Configuration

### Product IDs

The app uses the following StoreKit product IDs:

| Product | ID | Price Range |
|---------|-----|-------------|
| Monthly Premium | `com.pollenhealth.symptomtracker.premium.monthly` | £1.99-£4.99 |
| Yearly Premium | `com.pollenhealth.symptomtracker.premium.yearly` | £24.99 |

### Setting Up Products in App Store Connect

1. **Create Agreements**: Ensure you have an active Paid Apps agreement in App Store Connect
2. **Create Products**:
   - Go to your app → Features → Subscriptions
   - Create a new Subscription Group
   - Add products with the IDs above
   - Set pricing tier (Tier 1-6 for £1.99-£4.99)
3. **Configure in Xcode**:
   - Add StoreKit configuration file (StoreKit.config)
   - Or use App Store Connect for TestFlight testing

### Testing StoreKit

| Environment | How to Test |
|-------------|-------------|
| Simulator | StoreKit not fully functional; use TestFlight |
| TestFlight | Works with sandbox accounts |
| Local Testing | Use StoreKit configuration file in Xcode |

**Important**: StoreKit purchases won't work in the simulator. Use TestFlight with a sandbox account or a real device.

## Notification Testing

### Testing Local Notifications

1. **Request Permission**: App requests on first launch (during onboarding)
2. **Schedule Reminders**: Daily at 8 AM by default
3. **High Pollen Alerts**: Scheduled when pollen data indicates high levels

### Debugging Notifications

```swift
// In Xcode console, check for:
// - "Daily reminder scheduled for 8:0"
// - Notification permission status
```

### Testing on Device

1. Build and run on physical device (not simulator)
2. Go to Settings → Pollen Tracker → Enable notifications
3. Check notification appears at scheduled time

## Build Instructions

1. **Install XcodeGen** (if not already):
   ```bash
   brew install xcodegen
   ```

2. **Generate Xcode project**:
   ```bash
   cd PollenSymptomTracker
   xcodegen generate
   ```

3. **Open in Xcode**:
   ```bash
   open PollenSymptomTracker.xcodeproj
   ```

4. **Build and Run**:
   - Select a simulator or device
   - Press Cmd+R to build

## Configuration

### App-Specific Settings

- **Bundle Identifier**: `com.pollenhealth.symptomtracker`
- **Display Name**: "Pollen Tracker"
- **Minimum iOS**: 16.0

### API Keys

Add your API keys in the respective service files:
- `Services/AIService.swift` - For AI insights
- `Services/PollenAPIService.swift` - For pollen data

### Subscription Configuration

Edit `Resources/SubscriptionConfig.json` to customize:
- Price range
- Product features
- Pricing tiers

## Production Considerations

### App Store Submission

1. Test all subscription flows on TestFlight
2. Ensure Privacy Policy URL is configured
3. Configure in-app purchase metadata in App Store Connect

### StoreKit 2 Requirements

- iOS 16.0+ for full StoreKit 2 support
- Use `Product.purchase()` for subscriptions
- Handle `Transaction.updates` for subscription status
- Implement restore purchases functionality

### Error Handling

The app handles these StoreKit error scenarios:
- Network unavailable
- Product not available
- Purchase cancelled by user
- Payment not allowed (device restrictions)

## Testing

### Unit Tests

Run tests from Xcode (Cmd+U) or:
```bash
xcodebuild test -scheme PollenSymptomTracker
```

### Test Coverage

- `PaymentServiceTests.swift` - StoreKit integration
- `NotificationServiceTests.swift` - Notification scheduling
- `StorageServiceTests.swift` - Data persistence

## Known Limitations

1. **Simulator**: StoreKit purchases don't work in simulator
2. **TestFlight Required**: Full subscription testing needs TestFlight
3. **No Receipt Validation**: Production should include server-side validation
4. **Limited Persistence**: Uses UserDefaults; consider SQLite for scale

## Changelog (Production Pass v1)

See `research/pollen-symptom-tracker-production-pass-v1-2026-03-09.md` for detailed changelog.

---
Generated by App Factory Builder vNext
Production Pass: 2026-03-09
