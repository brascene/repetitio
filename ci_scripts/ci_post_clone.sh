#!/bin/sh

# Xcode Cloud Post-Clone Script
# This script runs after the repository is cloned but before the build starts
# It removes App Blocking extensions and capabilities for Release/TestFlight builds

set -e

echo "🔍 CI Post-Clone Script Started"
echo "Configuration: ${CI_XCODE_CONFIGURATION:-Unknown}"
echo "Workflow: ${CI_WORKFLOW:-Unknown}"

# Check if this is a Release build (not Debug)
if [ "$CI_XCODE_CONFIGURATION" != "Debug" ]; then
    echo "📦 Release build detected - removing App Blocking extensions and capabilities"

    # Navigate to project directory
    cd "$CI_PRIMARY_REPOSITORY_PATH"

    # Remove Family Controls capability from main app entitlements
    ENTITLEMENTS_FILE="YRepeat/YRepeat/YRepeat.entitlements"
    if [ -f "$ENTITLEMENTS_FILE" ]; then
        echo "🔧 Removing Family Controls from $ENTITLEMENTS_FILE"
        /usr/libexec/PlistBuddy -c "Delete :com.apple.developer.family-controls" "$ENTITLEMENTS_FILE" 2>/dev/null || echo "  ℹ️  Family Controls already removed or not found"
    fi

    # Remove App Groups capability if it's only used for app blocking
    # Uncomment the following lines if you want to remove app groups as well:
    # /usr/libexec/PlistBuddy -c "Delete :com.apple.security.application-groups" "$ENTITLEMENTS_FILE" 2>/dev/null || echo "  ℹ️  App Groups already removed or not found"

    # Note: We don't need to modify extension entitlements since the extensions
    # won't be embedded in Release builds (removed via project modification below)

    # Modify the project to exclude extension targets from Release builds
    PROJECT_FILE="YRepeat/YRepeat.xcodeproj/project.pbxproj"
    if [ -f "$PROJECT_FILE" ]; then
        echo "🔧 Removing embedded extensions from project for Release builds"

        # Create a backup
        cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

        # Remove the Embed Foundation Extensions build phase entries for the app blocking extensions
        # This prevents them from being built and embedded in Release builds

        echo "  🗑️  Removing YRepeatDeviceActivityMonitor from Embed Foundation Extensions"
        sed -i.bak '/YRepeatDeviceActivityMonitor\.appex in Embed Foundation Extensions/d' "$PROJECT_FILE"

        echo "  🗑️  Removing YRepeatShieldConfiguration from Embed Foundation Extensions"
        sed -i.bak '/YRepeatShieldConfiguration\.appex in Embed Foundation Extensions/d' "$PROJECT_FILE"

        # ALSO remove the Target Dependencies so they are not built at all
        # C4217B392EFC488200BEE804 is PBXTargetDependency for YRepeatDeviceActivityMonitor
        echo "  🗑️  Removing YRepeatDeviceActivityMonitor target dependency"
        sed -i.bak '/C4217B392EFC488200BEE804.*,/d' "$PROJECT_FILE"

        # C4217B532EFC4C3700BEE804 is PBXTargetDependency for YRepeatShieldConfiguration
        echo "  🗑️  Removing YRepeatShieldConfiguration target dependency"
        sed -i.bak '/C4217B532EFC4C3700BEE804.*,/d' "$PROJECT_FILE"

        # Clean up sed backup files
        rm -f "$PROJECT_FILE.bak"

        echo "  ✅ Extensions removed from Embed Foundation Extensions phase and Target Dependencies"
    fi

    echo "✅ Successfully removed App Blocking components for Release build"
else
    echo "🛠️  Debug build detected - keeping App Blocking extensions"
fi

echo "✨ CI Post-Clone Script Completed"
exit 0
