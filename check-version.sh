#!/bin/bash
# check-version.sh - Validates version consistency between pubspec.yaml and git tags

set -e  # Exit on any error

echo "🔍 Checking version consistency..."

# Navigate to the Flutter project directory
cd gauteng-wellbeing-mapper-app

# Get version from pubspec.yaml (remove build number)
PUBSPEC_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d ' ')
echo "📱 pubspec.yaml version: $PUBSPEC_VERSION"

# Get latest git tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
if [ "$LATEST_TAG" = "none" ]; then
    echo "📋 No git tags found"
    echo "ℹ️  Create your first tag with: git tag v$PUBSPEC_VERSION"
    exit 0
fi

LATEST_TAG_VERSION=${LATEST_TAG#v}  # Remove 'v' prefix
echo "🏷️  Latest git tag: $LATEST_TAG (version: $LATEST_TAG_VERSION)"

# Compare versions
if [ "$PUBSPEC_VERSION" = "$LATEST_TAG_VERSION" ]; then
    echo "✅ Versions match!"
    echo "ℹ️  Ready for release with version $PUBSPEC_VERSION"
else
    echo "❌ Version mismatch!"
    echo ""
    echo "Options to fix:"
    echo "1. Update pubspec.yaml to match latest tag ($LATEST_TAG_VERSION):"
    echo "   version: $LATEST_TAG_VERSION+[buildNumber]"
    echo ""
    echo "2. Or create new tag to match pubspec.yaml:"
    echo "   git tag v$PUBSPEC_VERSION"
    echo "   git push origin v$PUBSPEC_VERSION"
    echo ""
    exit 1
fi

echo "🚀 Version consistency validated!"
