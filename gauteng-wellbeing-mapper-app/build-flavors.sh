#!/bin/bash

# Build script for different app flavors
# Usage: ./build-flavors.sh [production|beta] [android|ios|all]

set -e

FLAVOR=${1:-production}
PLATFORM=${2:-all}

if [[ "$FLAVOR" != "production" && "$FLAVOR" != "beta" ]]; then
    echo "Error: Flavor must be 'production' or 'beta'"
    echo "Usage: $0 [production|beta] [android|ios|all]"
    exit 1
fi

if [[ "$PLATFORM" != "android" && "$PLATFORM" != "ios" && "$PLATFORM" != "all" ]]; then
    echo "Error: Platform must be 'android', 'ios', or 'all'"
    echo "Usage: $0 [production|beta] [android|ios|all]"
    exit 1
fi

echo "🚀 Building $FLAVOR flavor for $PLATFORM..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build Android
if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
    echo "📱 Building Android $FLAVOR APK..."
    flutter build apk --release \
        --flavor=$FLAVOR \
        --dart-define=APP_FLAVOR=$FLAVOR \
        --target-platform android-arm,android-arm64,android-x64
    
    echo "📱 Building Android $FLAVOR App Bundle..."
    flutter build appbundle --release \
        --flavor=$FLAVOR \
        --dart-define=APP_FLAVOR=$FLAVOR \
        --target-platform android-arm,android-arm64,android-x64
    
    echo "✅ Android $FLAVOR build complete!"
    echo "APK: build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"
    echo "AAB: build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
fi

# Build iOS
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
    echo "🍎 Building iOS $FLAVOR..."
    
    # Set the appropriate Info.plist for the flavor
    if [[ "$FLAVOR" == "production" ]]; then
        cp ios/Runner/Info-Production.plist ios/Runner/Info.plist
        echo "📄 Using Production Info.plist"
        BUNDLE_ID="com.github.activityspacelab.wellbeingmapper.gauteng"
    else
        cp ios/Runner/Info-Beta.plist ios/Runner/Info.plist
        echo "📄 Using Beta Info.plist"
        BUNDLE_ID="com.github.activityspacelab.wellbeingmapper.gauteng.beta"
    fi
    
    flutter build ios --release \
        --dart-define=APP_FLAVOR=$FLAVOR
    
    echo "✅ iOS $FLAVOR build complete!"
    echo "iOS build: build/ios/iphoneos/Runner.app"
    echo "Bundle ID: $BUNDLE_ID"
fi

echo "🎉 All builds completed successfully!"

if [[ "$FLAVOR" == "production" ]]; then
    echo ""
    echo "📋 Production Build Notes:"
    echo "• Only Private and Research modes are available"
    echo "• App Testing mode is not included"
    echo "• Ready for App Store submission"
elif [[ "$FLAVOR" == "beta" ]]; then
    echo ""
    echo "📋 Beta Build Notes:"
    echo "• All modes available: Private, Research, and App Testing"
    echo "• App name includes 'Beta' suffix"
    echo "• Separate bundle identifier for side-by-side installation"
fi
