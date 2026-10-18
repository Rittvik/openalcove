#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "==> Building OpenAlcove (Release)..."
swift build -c release

APP_DIR="$DIR/OpenAlcove.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "==> Copying binary..."
cp "$DIR/.build/release/OpenAlcove" "$APP_DIR/Contents/MacOS/"

echo "==> Copying resources and sounds..."
cp -R "$DIR/Sources/Resources/"* "$APP_DIR/Contents/Resources/"
if [ -f "$DIR/Alcove.app/Contents/Resources/AppIcon.icns" ]; then
    cp "$DIR/Alcove.app/Contents/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/"
fi

echo "==> Generating Info.plist..."
cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>OpenAlcove</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.openalcove.app</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>OpenAlcove</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.7.7</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSAppleEventsUsageDescription</key>
	<string>OpenAlcove needs permission to control playback and display music metadata.</string>
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>OpenAlcove needs permission to show connected AirPods and battery levels.</string>
	<key>NSCalendarsFullAccessUsageDescription</key>
	<string>OpenAlcove needs permission to display your upcoming calendar meetings.</string>
</dict>
</plist>
EOF

echo "==> Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_DIR"

echo "==> Successfully built $APP_DIR"
