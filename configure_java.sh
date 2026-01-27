#!/bin/bash
# Helper script to configure Java path for Gradle
# This script detects the correct Java installation for the current system
# and updates android/gradle.properties accordingly.

GRADLE_PROPS="android/gradle.properties"

# Define possible Java paths for different systems
JAVA_PATH_SYSTEM1="/home/abisin/android-studio/jbr"
JAVA_PATH_SYSTEM2="/home/abisinraj/development/jdk-17"

JAVA_HOME_TO_USE=""

# Check which Java path exists
if [ -d "$JAVA_PATH_SYSTEM1" ]; then
    JAVA_HOME_TO_USE="$JAVA_PATH_SYSTEM1"
    echo "Found Java at: $JAVA_PATH_SYSTEM1"
elif [ -d "$JAVA_PATH_SYSTEM2" ]; then
    JAVA_HOME_TO_USE="$JAVA_PATH_SYSTEM2"
    echo "Found Java at: $JAVA_PATH_SYSTEM2"
else
    echo "Error: No known Java installation found."
    echo "Please install Java or update this script with the correct path."
    exit 1
fi

# Update gradle.properties
if grep -q "^org.gradle.java.home=" "$GRADLE_PROPS"; then
    # Replace existing line
    sed -i "s|^org.gradle.java.home=.*|org.gradle.java.home=$JAVA_HOME_TO_USE|" "$GRADLE_PROPS"
    echo "Updated org.gradle.java.home in $GRADLE_PROPS"
elif grep -q "^# org.gradle.java.home=" "$GRADLE_PROPS"; then
    # Uncomment and update commented line
    sed -i "s|^# org.gradle.java.home=.*|org.gradle.java.home=$JAVA_HOME_TO_USE|" "$GRADLE_PROPS"
    echo "Uncommented and updated org.gradle.java.home in $GRADLE_PROPS"
else
    # Add new line
    echo "org.gradle.java.home=$JAVA_HOME_TO_USE" >> "$GRADLE_PROPS"
    echo "Added org.gradle.java.home to $GRADLE_PROPS"
fi

echo "✅ Java configuration complete!"
echo "   JAVA_HOME: $JAVA_HOME_TO_USE"
