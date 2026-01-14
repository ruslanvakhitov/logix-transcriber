#!/bin/bash

# Configuration
APP_ICON_SRC="app_icon_c_1768422457842.png"
MENUBAR_ICON_SRC="menubar_icon_c_1768422469736.png"
ASSETS_DIR="transcriber/Assets.xcassets"
APP_ICON_SET="$ASSETS_DIR/AppIcon.appiconset"
MENUBAR_ICON_SET="$ASSETS_DIR/MenuBarIcon.imageset"

# Artifacts path (assuming script is run from project root, but images are in artifacts dir)
ARTIFACTS_DIR="/Users/ruslanvakhitov/.gemini/antigravity/brain/63d968a4-a207-4222-863d-d6c7a34bad30"

# Note: We can't access ARTIFACTS_DIR directly in script if it's sandboxed, but run_command executes in shell.
# I will cp the images from absolute path.

echo "🎨 Processing App Icon..."
mkdir -p "$APP_ICON_SET"

# Copy full size
cp "$ARTIFACTS_DIR/$APP_ICON_SRC" "$APP_ICON_SET/icon_1024.png"

# Resize for various sizes
sips -z 16 16   "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_16x16.png"
sips -z 32 32   "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_16x16@2x.png"
sips -z 32 32   "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_32x32.png"
sips -z 64 64   "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_32x32@2x.png"
sips -z 128 128 "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_128x128.png"
sips -z 256 256 "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_128x128@2x.png"
sips -z 256 256 "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_256x256.png"
sips -z 512 512 "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_256x256@2x.png"
sips -z 512 512 "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_512x512.png"
sips -z 1024 1024 "$APP_ICON_SET/icon_1024.png" --out "$APP_ICON_SET/icon_512x512@2x.png"

# Create Contents.json for AppIcon
cat > "$APP_ICON_SET/Contents.json" <<EOF
{
  "images" : [
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16.png", "scale" : "1x" },
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16@2x.png", "scale" : "2x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32.png", "scale" : "1x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32@2x.png", "scale" : "2x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128.png", "scale" : "1x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128@2x.png", "scale" : "2x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256.png", "scale" : "1x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256@2x.png", "scale" : "2x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512.png", "scale" : "1x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512@2x.png", "scale" : "2x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
EOF

echo "🎨 Processing Menu Bar Icon..."
mkdir -p "$MENUBAR_ICON_SET"

# Resize for Menu Bar (18pt usually, so 18x18 and 36x36)
# Need to make sure it's template mode (black only)
# Using generic generated image
cp "$ARTIFACTS_DIR/$MENUBAR_ICON_SRC" "$MENUBAR_ICON_SET/original.png"

sips -z 18 18 "$MENUBAR_ICON_SET/original.png" --out "$MENUBAR_ICON_SET/icon_18x18.png"
sips -z 36 36 "$MENUBAR_ICON_SET/original.png" --out "$MENUBAR_ICON_SET/icon_18x18@2x.png"

# Create Contents.json for MenuBarIcon
cat > "$MENUBAR_ICON_SET/Contents.json" <<EOF
{
  "images" : [
    { "size" : "18x18", "idiom" : "mac", "filename" : "icon_18x18.png", "scale" : "1x" },
    { "size" : "18x18", "idiom" : "mac", "filename" : "icon_18x18@2x.png", "scale" : "2x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" },
  "properties" : { "template-rendering-intent" : "template" }
}
EOF

echo "✅ Icons processed"
