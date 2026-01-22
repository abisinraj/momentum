#!/bin/bash
# Helper script to install Momentum (Debug)
ADB_PATH="/home/abisinraj/Android/Sdk/platform-tools/adb"
APK_PATH="/home/abisinraj/Desktop/momentum/build/app/outputs/flutter-apk/app-debug.apk"

echo "Looking for adb at $ADB_PATH..."
if [ ! -f "$ADB_PATH" ]; then
    echo "Error: adb not found at $ADB_PATH"
    echo "Trying 'adb' from PATH..."
    ADB_PATH="adb"
fi

echo "Installing Momentum from $APK_PATH..."
"$ADB_PATH" install -r "$APK_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Success! Momentum installed."
else
    echo "❌ Installation failed. Please check:"
    echo "  1. Your device is connected via USB"
    echo "  2. USB Debugging is enabled on the device"
    echo "  3. You accepted the authorization popup on your phone"
fi
