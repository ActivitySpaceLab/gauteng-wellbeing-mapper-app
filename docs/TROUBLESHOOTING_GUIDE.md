# Wellbeing Mapper - Troubleshooting Guide

This document contains common issues, their solutions, and lessons learned during development. Keep this updated as new problems are discovered and resolved.

## Table of Contents
- [iOS Location Permissions](#ios-location-permissions)
- [Android Navigation Issues](#android-navigation-issues)
- [Build and Deployment Issues](#build-and-deployment-issues)
- [General Development Tips](#general-development-tips)

---

## iOS Location Permissions

### Issue: App Not Appearing in iOS Location Settings
**Problem:** iOS app does not appear in Settings > Privacy & Security > Location Services, permission requests fail silently, and `permission_handler` reports `ServiceStatus.disabled` even when Location Services are enabled system-wide.

**Root Cause:** The `Runner.entitlements` file exists but is not linked to the Xcode project configurations. iOS requires entitlements to be properly linked to recognize an app as location-capable.

**Solution:**
1. Check if `CODE_SIGN_ENTITLEMENTS` is set in Xcode Build Settings
2. If empty, add the following to `ios/Runner.xcodeproj/project.pbxproj` in all build configurations (Debug, Release, Profile):
   ```
   CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;
   ```
3. Ensure `Runner.entitlements` file contains at minimum:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
   </dict>
   </plist>
   ```

**Verification:**
- Build and install the app
- Check that `permission_handler` no longer reports `ServiceStatus.disabled`
- Verify app appears in iOS Settings > Privacy & Security > Location Services
- Test that permission requests work properly

**Key Lesson:** iOS location permissions require both `Info.plist` permission descriptions AND properly linked entitlements. The entitlements file can be empty but must be linked to the Xcode project.

---

## Android Navigation Issues

### Issue: Navigation Breaking After Build Configuration Changes
**Problem:** After modifying build configurations or dependencies, navigation routes stop working, causing crashes when trying to navigate between screens.

**Root Cause:** Changes to build configuration can sometimes affect the app's route registration or navigation state management.

**Solution:**
1. Clean build cache: `flutter clean`
2. Regenerate build files: `flutter pub get`
3. Rebuild completely: `flutter build apk` or `flutter build appbundle`
4. Check for any route definition conflicts in `MaterialApp` or route files

**Key Lesson:** After major build configuration changes, always perform a clean rebuild to avoid navigation state corruption.

---

## Build and Deployment Issues

### Issue: CI/CD Analysis Failures Due to Deprecated APIs
**Problem:** GitHub Actions CI fails with errors about deprecated `window` API usage in integration tests and syntax errors in test files.

**Error Messages:**
```
'window' is deprecated and shouldn't be used. Use WidgetTester.platformDispatcher or WidgetTester.view instead
Expected a method, getter, setter or operator declaration
Functions must have an explicit list of parameters
```

**Root Cause:** Flutter updated APIs in v3.9+ but integration test files were using deprecated `window` API and had structural syntax issues.

**Solution:**
1. **Update deprecated API usage:**
   ```dart
   // Old (deprecated)
   final size = binding.window.physicalSize;
   final ratio = binding.window.devicePixelRatio;
   final size = tester.binding.window.physicalSize;
   
   // New (current)
   final size = binding.platformDispatcher.views.first.physicalSize;
   final ratio = binding.platformDispatcher.views.first.devicePixelRatio;
   final size = tester.view.physicalSize;
   ```

2. **Fix file structure issues:**
   - Remove duplicate test method definitions
   - Ensure proper closing braces and brackets
   - Clean up malformed code blocks

3. **Remove unused imports:**
   ```dart
   // Remove unused imports like:
   import 'package:wellbeing_mapper/debug/ios_location_debug.dart';
   ```

**Verification:**
- Run `flutter analyze --no-fatal-infos` to check for remaining issues
- Run `flutter test` to ensure tests pass
- Check CI/CD pipeline passes all analysis steps

**Key Lesson:** Keep integration tests updated with Flutter API changes and regularly run analysis locally before pushing to avoid CI failures.

### Issue: iOS Provisioning Profile Entitlement Conflicts
**Problem:** Build fails with errors like "Provisioning profile doesn't include the [entitlement] entitlement" when using advanced entitlements.

**Root Cause:** Development provisioning profiles don't include advanced entitlements like `com.apple.developer.location.push` or `aps-environment`.

**Solution:**
1. For development builds, use minimal entitlements in `Runner.entitlements`
2. Remove advanced entitlements that aren't configured in the provisioning profile
3. For production builds, ensure App Store Connect app configuration includes required capabilities

**Key Lesson:** Development and production entitlements may differ. Keep development entitlements minimal to avoid provisioning conflicts.

### Issue: Flutter Version Conflicts
**Problem:** Build errors due to Flutter version mismatches between team members or CI/CD systems.

**Solution:**
1. Use `fvm` (Flutter Version Manager) to pin Flutter version
2. Ensure all team members use the same Flutter version specified in the project
3. Document required Flutter version in README.md

**Key Lesson:** Version consistency is critical for team development. Use version management tools.

---

## General Development Tips

### Debugging iOS Permissions
**Tools for Diagnosis:**
1. Create a temporary diagnostics screen to test `permission_handler` status
2. Use native iOS debugging tools to check entitlements loading
3. Verify app appears in iOS Settings before testing permission requests

**Essential Permission Debugging Code:**
```dart
// Check if iOS recognizes app as location-capable
final serviceStatus = await Permission.locationWhenInUse.serviceStatus;
print('Service Status: $serviceStatus'); // Should not be 'disabled'

// Check current permission status
final permission = await Permission.locationWhenInUse.status;
print('Permission Status: $permission');
```

### iOS Info.plist Requirements
**Required Location Permission Keys:**
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription` 
- `NSLocationWhenInUseUsageDescription`
- `NSLocationUsageDescription` (legacy)
- `NSMotionUsageDescription` (for motion data)

**Background Location Requirements:**
- Add `location` to `UIBackgroundModes` array
- Configure `BGTaskSchedulerPermittedIdentifiers` for background tasks

### Code Signing Best Practices
1. Use manual code signing for consistent builds
2. Keep entitlements minimal for development
3. Document any required provisioning profile capabilities
4. Test builds on physical devices, not just simulator

---

## Historical Issues Resolved

### 2025-07-28: iOS Location Permission Recognition
- **Issue:** Major iOS location permission failure after App Store deployment changes
- **Investigation:** Multi-day debugging through permission_handler, native approaches, git history analysis
- **Resolution:** Discovered missing `CODE_SIGN_ENTITLEMENTS` linking in Xcode project
- **Impact:** Complete resolution of iOS location functionality

### Previous Android Navigation Architecture Refactor
- **Issue:** Navigation routing conflicts after architectural changes
- **Resolution:** Rebuilt navigation system with proper route management
- **Impact:** Stable navigation across both platforms

---

## Prevention Strategies

1. **Always test on physical devices** before major releases
2. **Verify entitlements are properly linked** after any iOS configuration changes
3. **Use diagnostic screens** during development to catch permission issues early
4. **Document build configuration changes** that affect permissions or capabilities
5. **Test permission flows end-to-end** on both platforms before release

---

## Quick Reference Commands

```bash
# Clean rebuild (when navigation or build issues occur)
flutter clean && flutter pub get && flutter build ios --release

# Check iOS entitlements linking
grep -r "CODE_SIGN_ENTITLEMENTS" ios/Runner.xcodeproj/project.pbxproj

# Verify Flutter version consistency
fvm list
fvm use [version]

# Test iOS build with verbose output
flutter build ios --release --verbose
```

---

**Note:** Keep this document updated with new issues and solutions as they arise. This serves as institutional knowledge for the development team.
