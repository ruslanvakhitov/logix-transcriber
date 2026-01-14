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

echo "📦 Exporting App..."
# Since we don't have a dev cert, we just copy the app from archive
# This avoids export errors with ad-hoc signing
cp -R "build/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app" "dist/"

if [ $? -ne 0 ]; then
    echo "❌ Export failed"
    exit 1
fi

echo "💿 Creating DMG..."
hdiutil create -volname "Logix Transcriber" \
               -srcfolder "dist/$APP_NAME.app" \
               -ov -format UDZO \
               "dist/$DMG_NAME.dmg"

if [ $? -ne 0 ]; then
    echo "❌ DMG creation failed"
    exit 1
fi

echo "✅ Build Complete!"
echo "📂 Output: dist/$DMG_NAME.dmg"
