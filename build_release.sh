#!/bin/bash

# Configuration
APP_NAME="transcriber"
SCHEME_NAME="transcriber"
DMG_NAME="LogixTranscriber_v1.2.0"

# Clean build directory
rm -rf build dist
mkdir -p build dist

echo "🚀 Archiving..."
xcodebuild -project transcriber.xcodeproj \
           -scheme "$SCHEME_NAME" \
           -destination "generic/platform=macOS" \
           -archivePath "build/$APP_NAME.xcarchive" \
           -configuration Release \
           archive \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO

if [ $? -ne 0 ]; then
    echo "❌ Archive failed"
    exit 1
fi

echo "📦 Exporting App..."
BUILD_APP_NAME="transcriber"
TARGET_APP_NAME="LogixTranscriber"

cp -R "build/$APP_NAME.xcarchive/Products/Applications/$BUILD_APP_NAME.app" "dist/$TARGET_APP_NAME.app"

if [ $? -ne 0 ]; then
    echo "❌ Export failed"
    exit 1
fi

echo "🔓 Removing code signature (fixes TCC permission issues)..."
# Remove signature from main binary
codesign --remove-signature "dist/$TARGET_APP_NAME.app/Contents/MacOS/$BUILD_APP_NAME" 2>/dev/null || true
# Remove signature from app bundle
codesign --remove-signature "dist/$TARGET_APP_NAME.app" 2>/dev/null || true
# Remove any extended attributes
xattr -cr "dist/$TARGET_APP_NAME.app"

echo "💿 Creating DMG with Applications link..."
# Create temp folder for DMG contents
mkdir -p "dist/dmg_content"
cp -R "dist/$TARGET_APP_NAME.app" "dist/dmg_content/"
ln -s /Applications "dist/dmg_content/Applications"

hdiutil create -volname "Logix Transcriber" \
               -srcfolder "dist/dmg_content" \
               -ov -format UDZO \
               "dist/$DMG_NAME.dmg"

# Cleanup
rm -rf "dist/dmg_content"

if [ $? -ne 0 ]; then
    echo "❌ DMG creation failed"
    exit 1
fi

echo "✅ Build Complete!"
echo "📂 Output: dist/$DMG_NAME.dmg"
echo ""
echo "📋 Installation instructions:"
echo "   1. Open the DMG"
echo "   2. Drag LogixTranscriber to Applications"
echo "   3. Run: xattr -cr /Applications/LogixTranscriber.app"
echo "   4. Open the app and grant permissions"
