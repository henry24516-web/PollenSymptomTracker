# Secrets Setup Guide

This guide explains how to configure the required secrets for App Store distribution builds in GitHub Actions.

## Required Secrets Overview

| Secret | Required For | How to Get |
|--------|--------------|------------|
| `APPLE_CERTIFICATE_P12` | Code signing | Export from Keychain |
| `APPLE_CERTIFICATE_PASSWORD` | Code signing | Set when exporting certificate |
| `KEYCHAIN_PASSWORD` | CI keychain | Generate a secure password |
| `PROVISIONING_PROFILE` | App installation | Download from Apple Developer Portal |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect | Create API key in App Store Connect |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | App Store Connect | From API key creation |
| `APP_STORE_CONNECT_API_KEY_KEY` | App Store Connect | Download .p8 file |
| `BUNDLE_ID` | Build configuration | From Xcode project |

---

## Step 1: Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **Users and Access**
3. Go to **Keys** tab
4. Click **+** to create a new key
5. Name: `GitHub Actions`
6. Access: **App Manager** (or appropriate role)
7. Download the `.p8` file (only available once!)
8. Note the **Key ID** and **Issuer ID**

---

## Step 2: Create/Update Provisioning Profile

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Profiles**
3. Create a new profile or update existing:
   - Type: **App Store Distribution**
   - Bundle ID: `com.pollenhealth.symptomtracker`
   - Certificates: Select your distribution certificate
4. Download the `.mobileprovision` file

---

## Step 3: Export Certificate

### Option A: Using Keychain Access (Recommended)

1. Open **Keychain Access** on your Mac
2. Find your **Apple Distribution** certificate
3. Right-click → **Export**
4. Format: **Personal Information Exchange (.p12)**
5. Set a password (note this - it's `APPLE_CERTIFICATE_PASSWORD`)
6. Save the file

### Option B: Using fastlane match (Alternative)

```bash
# Install match
brew install fastlane

# Initialize (for existing certs)
match import

# Or generate new
match appstore --app_identifier com.pollenhealth.symptomtracker
```

---

## Step 4: Convert Files to Base64

All secrets must be base64-encoded:

### macOS/Linux

```bash
# Certificate (.p12)
base64 -i certificate.p12 -o certificate_base64.txt

# Provisioning Profile
base64 -i "PollenSymptomTracker.mobileprovision" -o profile_base64.txt

# API Key (.p8)
base64 -i AuthKey_XXXX.p8 -o apikey_base64.txt
```

### PowerShell (Windows)

```powershell
# Certificate
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("certificate.p12")) | Out-File -FilePath certificate_base64.txt

# Provisioning Profile
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("PollenSymptomTracker.mobileprovision")) | Out-File -FilePath profile_base64.txt
```

---

## Step 5: Add Secrets to GitHub

1. Go to your repository on GitHub
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add each secret:

| Name | Value |
|------|-------|
| `APPLE_CERTIFICATE_P12` | Content of `certificate_base64.txt` |
| `APPLE_CERTIFICATE_PASSWORD` | Password you set when exporting .p12 |
| `KEYCHAIN_PASSWORD` | Generate a random password (e.g., `openssl rand -base64 32`) |
| `PROVISIONING_PROFILE` | Content of `profile_base64.txt` |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from Step 1 (e.g., `XXXXXXXXXX`) |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID from Step 1 (e.g., `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`) |
| `APP_STORE_CONNECT_API_KEY_KEY` | Content of `apikey_base64.txt` |
| `BUNDLE_ID` | `com.pollenhealth.symptomtracker` |

---

## Step 6: Create ExportOptions.plist

Create `ExportOptions.plist` in your project root:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

Replace `YOUR_TEAM_ID` with your Apple Developer Team ID (found in Apple Developer Portal).

---

## Verify Setup

1. Push changes to `main` branch
2. Go to **Actions** tab
3. Watch the **archive** job
4. If successful, you'll see `PollenSymptomTracker.ipa` in artifacts

---

## Troubleshooting

### "No matching signing identity found"
- Check your certificate is valid and not expired
- Ensure provisioning profile matches the certificate

### "Invalid API Key"
- Verify Key ID and Issuer ID are correct
- Check the .p8 file was correctly converted to base64

### "Could not resolve hostname"
- Network issue; check GitHub Actions runner can reach Apple servers

### "Profile not found"
- Ensure provisioning profile is installed in CI
- Check the profile name matches what's expected

## Security Notes

- Never commit secrets to git
- Rotate API keys periodically
- Use separate secrets for production vs. development
- Consider using GitHub's environment protection rules for production secrets
