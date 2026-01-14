#!/bin/bash

# Configuration
APP_NAME="transcriber"
SCHEME_NAME="transcriber"
DMG_NAME="LogixTranscriber_v1.1.0"

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
           CODE_SIGN_IDENTITY="-" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO

if [ $? -ne 0 ]; then
    echo "❌ Archive failed"
    exit 1
fi

echo "📦 Preparing DMG content..."
APP_DST="dist/dmg_content"
rm -rf "$APP_DST"
mkdir -p "$APP_DST"

BUILD_APP_NAME="transcriber"
TARGET_APP_NAME="LogixTranscriber"

# Copy App to DMG content folder
cp -R "build/$APP_NAME.xcarchive/Products/Applications/$BUILD_APP_NAME.app" "$APP_DST/$TARGET_APP_NAME.app"

# Create Applications symlink
ln -s /Applications "$APP_DST/Applications"

if [ $? -ne 0 ]; then
    echo "❌ Preparation failed"
    exit 1
fi

echo "💿 Creating DMG..."
rm -f "dist/$DMG_NAME.dmg"
hdiutil create -volname "Logix Transcriber" \
               -srcfolder "$APP_DST" \
               -ov -format UDZO \
               "dist/$DMG_NAME.dmg"

if [ $? -ne 0 ]; then
    echo "❌ DMG creation failed"
    exit 1
fi

echo "✅ Build Complete!"
echo "📂 Output: dist/$DMG_NAME.dmg"
