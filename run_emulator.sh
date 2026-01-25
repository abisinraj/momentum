#!/bin/bash
export JAVA_HOME="$HOME/development/jdk-17"
export ANDROID_SDK_ROOT="$HOME/development/android-sdk"
export ANDROID_AVD_HOME="$HOME/.android/avd"
export PATH="$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"

echo "Starting Flutter Emulator..."
$ANDROID_SDK_ROOT/emulator/emulator -avd flutter_emulator -netdelay none -netspeed full &
