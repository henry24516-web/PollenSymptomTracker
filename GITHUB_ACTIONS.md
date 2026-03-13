# GitHub Actions CI/CD Setup

This document explains how to use the GitHub Actions workflow for building and testing the PollenSymptomTracker iOS app.

## Overview

The workflow (`.github/workflows/build.yml`) provides:

1. **Build** - Compiles the app in both Debug and Release configurations
2. **Test** - Runs unit tests
3. **Archive** - Builds an IPA for App Store distribution (requires secrets)

## Quick Start

### 1. Push to GitHub

Push this code to a GitHub repository:

```bash
git init
git add .
git commit -m "Add GitHub Actions CI/CD"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/PollenSymptomTracker.git
git push -u origin main
```

### 2. Enable GitHub Actions

1. Go to your repository on GitHub
2. Navigate to **Actions** tab
3. The workflow will be detected automatically
4. Click "I understand my workflows, go ahead and enable them"

### 3. Initial Build (No Secrets Required)

The basic build and test jobs run without any secrets:
- Push to `main` or `develop` branch
- Creates a Pull Request
- Watch the Actions tab for build results

### 4. Configure Secrets (For App Store Deployment)

To build an IPA for App Store distribution, add these secrets:

| Secret | Description |
|--------|-------------|
| `APPLE_CERTIFICATE_P12` | Base64-encoded .p12 certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the .p12 certificate |
| `KEYCHAIN_PASSWORD` | Password for the CI keychain |
| `PROVISIONING_PROFILE` | Base64-encoded .mobileprovision file |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | App Store Connect API Key Issuer ID |
| `APP_STORE_CONNECT_API_KEY_KEY` | App Store Connect API Key (base64 encoded .p8 content) |
| `BUNDLE_ID` | Bundle ID (e.g., `com.pollenhealth.symptomtracker`) |

See [SECRETS_SETUP.md](./SECRETS_SETUP.md) for detailed instructions.

## Workflow Details

### Jobs

| Job | Description | Required Secrets |
|-----|-------------|------------------|
| `build` | Compiles Debug + Release | No |
| `test` | Runs unit tests | No |
| `archive` | Creates IPA for App Store | Yes |

### Running the Workflow

**Automatic:**
- On push to `main` or `develop`
- On Pull Requests

**Manual:**
- Go to Actions → Build iOS App → Run workflow

### Available Simulators

The workflow builds for `iPhone 15 Pro` simulator. To change this, edit the `destination` parameter in `build.yml`:

```yaml
# Examples:
-destination 'platform=iOS Simulator,name=iPhone 15'
-destination 'platform=iOS Simulator,name=iPhone 15 Pro Max'
-destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (M2)'
```

## Troubleshooting

### "Xcode version not found"
The workflow uses Xcode 15.4. Update the `DEVELOPER_DIR` if you need a different version.

### "Scheme not found"
Make sure the scheme name matches your target name: `PollenSymptomTracker`

### "Podfile not found"
If you're not using CocoaPods, the workflow handles this automatically. If you add CocoaPods later, commit the `Podfile.lock`.

### Certificate/Provisioning Issues
See [SECRETS_SETUP.md](./SECRETS_SETUP.md) for detailed certificate setup instructions.

## Adding More Steps

### Code Signing for Development

For development builds with automatic code signing:

```yaml
- name: Build with auto-signing
  run: |
    xcodebuild -project PollenSymptomTracker.xcodeproj \
      -scheme PollenSymptomTracker \
      -configuration Debug \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
      CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
      build
```

### Upload to TestFlight

Add a step to the archive job:

```yaml
- name: Upload to TestFlight
  run: |
    xcrun altool --upload-app \
      -f build/PollenSymptomTracker.ipa \
      -u "your-apple-id@email.com" \
      -p "app-specific-password"
```

## Support

- GitHub Actions: https://github.com/features/actions
- XcodeGen: https://github.com/yonaskolb/XcodeGen
