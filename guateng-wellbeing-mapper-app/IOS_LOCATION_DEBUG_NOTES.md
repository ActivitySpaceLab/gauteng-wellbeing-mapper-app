# iOS Location Permission Investigation

## Problem Summary
The iOS version of the Wellbeing Mapper app is not appearing in the iOS location settings, preventing users from granting location permissions to the app.

## Symptoms
- App doesn't appear in **Settings > Privacy & Security > Location Services**
- App doesn't appear in the per-app location settings list
- Users cannot manually grant location permissions
- Location tracking doesn't work despite proper Info.plist configuration

## Current Status
✅ **Build Configuration Verified**: All required location permission keys are properly included in Info.plist:
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `NSLocationUsageDescription`

✅ **Permission Framework Verified**: `permission_handler_apple` is properly included and linked

❌ **System Registration**: App not appearing in iOS system location settings

## Debug Tool Added
Created `IosLocationDebugScreen` accessible from the side drawer menu:
- **Location**: Accessible via hamburger menu → "iOS Location Debug"
- **Features**:
  - Check current permission status
  - Request various permission types
  - Open app settings
  - View detailed permission state

## Investigation Steps
1. **Deploy the updated app** with the debug screen to iOS device
2. **Open the debug screen** from the side drawer
3. **Check current permission status** to see what iOS reports
4. **Try requesting permissions** to see if requests trigger system dialogs
5. **Check if app appears in settings** after permission requests

## Potential Causes
1. **App Bundle ID mismatch** - iOS might not recognize the app properly
2. **Code signing issues** - App might not be properly signed for location services
3. **Permission request timing** - App might not be requesting permissions at the right time
4. **iOS version compatibility** - Permission handling might differ across iOS versions
5. **Background geolocation plugin conflict** - Multiple location libraries might interfere

## Next Steps
1. Test with the debug tool to identify exact permission status
2. Verify app bundle ID and signing
3. Check if permissions work in debug vs release builds
4. Test on different iOS versions
5. Investigate background geolocation plugin integration

## Files Modified
- `/lib/debug/ios_location_debug.dart` - New debug screen
- `/lib/ui/side_drawer.dart` - Added access to debug screen

## Test Build
- ✅ iOS Release build completed (42.5MB)
- Ready for deployment and testing
