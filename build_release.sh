#!/bin/bash

# Configuration
APP_NAME="transcriber"
SCHEME_NAME="transcriber"
DMG_NAME="LogixTranscriber_v1.2.1"

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
           CODE_SIGNING_REQUIRED=YES \
           CODE_SIGNING_ALLOWED=YES

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

echo "🔐 Re-signing app with fresh ad-hoc signature..."
# Re-sign all frameworks and binaries inside the app
find "dist/$TARGET_APP_NAME.app" -name "*.dylib" -o -name "*.framework" | while read f; do
    codesign --force --deep --sign - "$f" 2>/dev/null || true
done
# Re-sign the main app bundle
codesign --force --deep --sign - "dist/$TARGET_APP_NAME.app"

# Clear extended attributes
xattr -cr "dist/$TARGET_APP_NAME.app"

echo "💿 Creating DMG with Applications link..."
mkdir -p "dist/dmg_content"
cp -R "dist/$TARGET_APP_NAME.app" "dist/dmg_content/"
ln -s /Applications "dist/dmg_content/Applications"

hdiutil create -volname "Logix Transcriber" \
               -srcfolder "dist/dmg_content" \
               -ov -format UDZO \
               "dist/$DMG_NAME.dmg"

rm -rf "dist/dmg_content"

if [ $? -ne 0 ]; then
    echo "❌ DMG creation failed"
    exit 1
fi

echo "✅ Build Complete!"
echo "📂 Output: dist/$DMG_NAME.dmg"
echo ""
echo "📋 Installation:"
echo "   1. Open DMG, drag to Applications"
echo "   2. Run: xattr -cr /Applications/LogixTranscriber.app"
echo "   3. Open app (Right-click → Open first time)"
echo "   4. Grant permissions, enable 'Bypass' toggle in Settings if needed"

