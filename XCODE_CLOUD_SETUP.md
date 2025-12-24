# Xcode Cloud Build Setup for App Blocking Feature

## Problem
The App Blocking feature uses Family Controls capability which requires Apple approval for production. This causes Xcode Cloud builds to fail for TestFlight/Release builds.

## Solution Overview
We've implemented a multi-layered approach to exclude App Blocking components from Release builds:

### ✅ Already Implemented

1. **Code Conditionals**: All App Blocking code is wrapped in `#if DEBUG` blocks
2. **Post-Clone Script**: Created `ci_scripts/ci_post_clone.sh` that automatically removes Family Controls capability from Release builds

### 🔧 Additional Setup Required

You need to configure the extension targets to only build for Debug configuration:

#### Option A: Configure in Xcode (Recommended)

**For YRepeatDeviceActivityMonitor:**
1. Open `YRepeat.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the **YRepeatDeviceActivityMonitor** target
4. Go to **Build Settings** tab
5. Search for "Excluded Architectures"
6. Under **Release** configuration, add: `$(ARCHS_STANDARD)`
7. Or search for "Skip Install" and set it to `YES` for Release

**For YRepeatShieldConfiguration:**
1. Repeat the same steps for the **YRepeatShieldConfiguration** target

#### Option B: Exclude from Xcode Cloud Workflow

1. Go to Xcode Cloud workflow settings in App Store Connect
2. Edit your workflow
3. Under "Build" section, click "Environment"
4. Add a custom build setting:
   - For Debug builds: Build all targets
   - For Release builds: Exclude extension targets

#### Option C: Configure Build Schemes

1. In Xcode, go to **Product > Scheme > Edit Scheme**
2. Select the **Archive** build action (used for TestFlight)
3. Uncheck the boxes for:
   - YRepeatDeviceActivityMonitor
   - YRepeatShieldConfiguration
4. This ensures extensions are not built for Archive/Release

## How It Works

### Debug Builds
- ✅ Family Controls capability enabled
- ✅ Extension targets built and included
- ✅ App Blocking feature fully functional

### Release/TestFlight Builds
- ❌ Family Controls capability removed (via script)
- ❌ Extension targets excluded (via Xcode config)
- ❌ App Blocking code excluded (via #if DEBUG)
- ✅ App builds and ships successfully

## Testing

### Test the Script Locally
```bash
# Simulate Release build
CI_XCODE_CONFIGURATION=Release ./ci_scripts/ci_post_clone.sh

# Simulate Debug build
CI_XCODE_CONFIGURATION=Debug ./ci_scripts/ci_post_clone.sh
```

### Verify in Xcode Cloud
1. Push changes to repository
2. Check Xcode Cloud build logs
3. Look for post-clone script output
4. Verify extensions are not built for Release

## Files Modified

- ✅ `ci_scripts/ci_post_clone.sh` - Post-clone script (auto-runs in Xcode Cloud)
- ✅ All App Blocking code wrapped in `#if DEBUG`

## Troubleshooting

### Build still failing?

1. **Check Script Execution**: Look at Xcode Cloud logs for "CI Post-Clone Script" output
2. **Verify Configuration**: Ensure `CI_XCODE_CONFIGURATION` is set to "Release" or "Archive"
3. **Check Entitlements**: Verify Family Controls was removed from entitlements
4. **Extension Targets**: Ensure extensions are excluded from the build scheme

### Script not running?

- Ensure `ci_scripts/ci_post_clone.sh` is executable: `chmod +x ci_scripts/ci_post_clone.sh`
- Ensure the file is committed to git
- Check Xcode Cloud environment has access to the script

## Alternative: Manual Configuration

If scripts don't work, you can manually configure:

1. Create separate build configurations (Debug, Release)
2. Create separate targets (Debug-only versions)
3. Use different schemes for Debug vs Release
4. Manually manage entitlements for each configuration

## Need Help?

If builds continue to fail:
1. Check Xcode Cloud build logs for specific errors
2. Verify all extension targets are excluded
3. Confirm Family Controls is removed from entitlements
4. Try building locally with Release configuration first
