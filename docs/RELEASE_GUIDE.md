# Release Management Guide

This document explains the release process for Wellbeing Mapper, including both manual and automated approaches.

## Release Approaches

### 1. Automated Releases (Recommended for Production)

**When to Use:**
- Production releases
- Version-tagged releases
- When you want automated testing and consistent builds

**How it Works:**
1. Create and push a version tag (e.g., `v1.0.0`)
2. GitHub Actions automatically builds both Android and iOS
3. Creates a GitHub release with all artifacts
4. Includes automated testing and code analysis

**Steps:**
```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically:
# 1. Run tests and analysis
# 2. Build Android APK and AAB (release)
# 3. Build iOS app (release, no-codesign)
# 4. Create GitHub release with artifacts
```

### 2. Manual Releases (For Testing and Quick Builds)

**When to Use:**
- Local testing
- Quick iterations
- When you need signed iOS builds immediately

**How it Works:**
Use the `build-release.sh` script which builds both platforms locally.

**Steps:**
```bash
# Make script executable (first time only)
chmod +x build-release.sh

# Run the release build script
./build-release.sh
```

## Build Outputs

### Android
- **App Bundle (AAB)**: `build/app/outputs/bundle/release/app-release.aab`
  - Upload to Google Play Console
  - Recommended for Play Store distribution
- **APK Files**: `build/app/outputs/flutter-apk/`
  - `app-arm64-v8a-release.apk` (64-bit ARM)
  - `app-armeabi-v7a-release.apk` (32-bit ARM)
  - `app-x86_64-release.apk` (64-bit Intel)

### iOS
- **App Build**: `build/ios/iphoneos/Runner.app`
  - Must be archived in Xcode for App Store distribution
  - Cannot be directly distributed without code signing

## Distribution Process

### Android Distribution

#### Google Play Store (Recommended)
1. Build using either method above
2. Upload `app-release.aab` to Google Play Console
3. Follow Google Play's release process

#### Direct APK Distribution
1. Use the APK files from `build/app/outputs/flutter-apk/`
2. Distribute directly to users (enable "Unknown Sources")

### iOS Distribution

#### App Store (Production)
1. Build using either method above
2. Open `ios/Runner.xcworkspace` in Xcode
3. Archive the app (Product → Archive)
4. Upload to App Store Connect via Xcode Organizer

#### TestFlight (Beta Testing)
1. Same as App Store process
2. After upload, enable TestFlight in App Store Connect
3. Add beta testers

## Release Checklist

### Pre-Release
- [ ] Update version number in `pubspec.yaml`
- [ ] Update changelog/release notes
- [ ] Test on both iOS and Android devices
- [ ] Verify location permissions work correctly
- [ ] Run all tests locally: `flutter test`
- [ ] Verify no lint issues: `flutter analyze`

### Release Process
- [ ] Choose release method (automated vs manual)
- [ ] If automated: Create and push version tag
- [ ] If manual: Run `./build-release.sh`
- [ ] Verify build artifacts are created successfully
- [ ] Test release builds on physical devices

### Post-Release
- [ ] Upload Android AAB to Google Play Console
- [ ] Archive and upload iOS app via Xcode
- [ ] Update documentation if needed
- [ ] Monitor for any release-specific issues

## Version Tagging

Use semantic versioning for releases:
- `v1.0.0` - Major release
- `v1.1.0` - Minor release with new features
- `v1.0.1` - Patch release with bug fixes

## GitHub Actions Workflow

The automated workflow (`.github/workflows/CD-deploy-github-releases.yml`) includes:

1. **Code Quality Checks**
   - Static analysis with `flutter analyze`
   - Unit tests with `flutter test`

2. **Multi-Platform Builds**
   - Android: APK + App Bundle (release)
   - iOS: Release build (no code signing)

3. **Artifact Management**
   - Uploads all build artifacts to GitHub release
   - Includes comprehensive release notes

4. **Requirements**
   - Runs on macOS for iOS builds
   - Uses Flutter 3.27.1 to match local development
   - Requires `GITHUB_TOKEN` secret (automatically provided)

## Troubleshooting

### iOS Code Signing Issues
If you encounter code signing issues during manual builds:
1. Ensure your development team is properly configured in Xcode
2. Check that entitlements are properly linked (see `TROUBLESHOOTING_GUIDE.md`)
3. Use the `--no-codesign` flag for CI builds

### Android Build Issues
- Ensure Java 17 is installed for local builds
- Clear build cache with `flutter clean` if issues persist
- Verify Android SDK is properly configured

### GitHub Actions Failures
- Check that the workflow file syntax is correct
- Ensure the repository has necessary permissions for releases
- Verify that tests pass locally before pushing tags

## Best Practices

1. **Always test release builds** on physical devices before distribution
2. **Use semantic versioning** for clear version communication
3. **Keep release notes updated** for user transparency
4. **Test location permissions specifically** as they're critical for this app
5. **Use automated releases for production** to ensure consistency
6. **Keep manual scripts for quick testing** and development iterations

## Quick Reference

```bash
# Local release build
./build-release.sh

# Automated release
git tag v1.0.0 && git push origin v1.0.0

# Test release build locally
flutter build apk --release
flutter build ios --release

# Clean build (if issues)
flutter clean && flutter pub get
```
