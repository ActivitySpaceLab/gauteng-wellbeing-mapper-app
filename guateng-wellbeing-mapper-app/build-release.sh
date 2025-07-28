#!/bin/bash

# Build script for Wellbeing Mapper
# This script builds both Android and iOS versions for release

echo "🚀 Building Wellbeing Mapper for release..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
fvm flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
fvm flutter pub get

# Build Android App Bundle (recommended for Play Store)
echo "🤖 Building Android App Bundle..."
fvm flutter build appbundle

# Build Android APKs (alternative distribution)
echo "🤖 Building Android APKs..."
fvm flutter build apk --split-per-abi

# Install iOS dependencies
echo "🍎 Installing iOS dependencies..."
cd ios && pod install && cd ..

# Build iOS (for later archiving in Xcode)
echo "🍎 Building iOS..."
fvm flutter build ios --release --no-codesign

echo "✅ Build complete!"
echo ""
echo "📁 Output files:"
echo "  Android App Bundle: build/app/outputs/bundle/release/app-release.aab"
echo "  Android APKs: build/app/outputs/flutter-apk/"
echo "  iOS App: build/ios/iphoneos/Runner.app"
echo ""
echo "📋 Next steps:"
echo "  1. Upload Android AAB to Google Play Console"
echo "  2. Archive iOS app in Xcode for App Store Connect"
echo "  3. Create GitHub release with both builds"
