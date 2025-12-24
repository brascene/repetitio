#!/bin/sh

# Xcode Cloud Post-Clone Script
# This script runs after the repository is cloned but before the build starts
# It removes App Blocking extensions and capabilities for Release/TestFlight builds

set -e

echo "🔍 CI Post-Clone Script Started"
echo "Configuration: ${CI_XCODE_CONFIGURATION:-Unknown}"
echo "Workflow: ${CI_WORKFLOW:-Unknown}"
echo "Workspace Path: $CI_PRIMARY_REPOSITORY_PATH"

# Safety check for local runs
if [ -z "$CI_XCODE_CONFIGURATION" ]; then
    echo "⚠️  No CI_XCODE_CONFIGURATION found. Skipping script to protect local project."
    exit 0
fi

if [ "$CI_XCODE_CONFIGURATION" != "Debug" ]; then
    echo "📦 Release build detected - removing App Blocking extensions and capabilities"

    # Navigate to project directory
    cd "$CI_PRIMARY_REPOSITORY_PATH"

    # --- Entitlements ---
    # Find the entitlements file dynamically to avoid path issues
    ENTITLEMENTS_FILE=$(find . -name "YRepeat.entitlements" -print -quit)
    
    if [ -n "$ENTITLEMENTS_FILE" ]; then
        echo "🔧 Found entitlements at: $ENTITLEMENTS_FILE"
        echo "   Content before modification:"
        cat "$ENTITLEMENTS_FILE"
        
        # Remove Family Controls capability
        /usr/libexec/PlistBuddy -c "Delete :com.apple.developer.family-controls" "$ENTITLEMENTS_FILE" 2>/dev/null || echo "  ℹ️  Family Controls key not found in entitlements"
        
        echo "   Content after modification:"
        cat "$ENTITLEMENTS_FILE"
    else
        echo "⚠️  ERROR: YRepeat.entitlements file not found!"
        exit 1
    fi

    # --- Project File ---
    PROJECT_FILE=$(find . -name "project.pbxproj" -path "*/YRepeat.xcodeproj/*" -print -quit)
    
    if [ -n "$PROJECT_FILE" ]; then
        echo "🔧 Found project file at: $PROJECT_FILE"
        
        # Create a backup
        cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

        # 1. Remove Extensions from "Embed Foundation Extensions" build phase
        # Look for the IDs or names. We use the names for safety.
        # Removing lines containing "YRepeatDeviceActivityMonitor.appex in Embed Foundation Extensions"
        sed -i.bak '/YRepeatDeviceActivityMonitor\.appex in Embed Foundation Extensions/d' "$PROJECT_FILE"
        sed -i.bak '/YRepeatShieldConfiguration\.appex in Embed Foundation Extensions/d' "$PROJECT_FILE"
        
        # 2. Remove Target Dependencies
        # These are the PBXTargetDependency objects in the 'dependencies' list of the main target
        # We look for the object IDs we found earlier, but to be robust we can search for the comment
        # "PBXTargetDependency" and the target name if possible, but IDs are safer if they don't change.
        # IDs:
        # C4217B392EFC488200BEE804 -> YRepeatDeviceActivityMonitor dependency
        # C4217B532EFC4C3700BEE804 -> YRepeatShieldConfiguration dependency
        
        echo "   Removing Target Dependencies..."
        sed -i.bak '/C4217B392EFC488200BEE804.*,/d' "$PROJECT_FILE"
        sed -i.bak '/C4217B532EFC4C3700BEE804.*,/d' "$PROJECT_FILE"

        # 3. Clean up any lingering Framework links if they exist in PBXFrameworksBuildPhase
        # (Though we didn't see them in the main target, good to be safe)
        # DeviceActivity.framework, FamilyControls.framework, ManagedSettings.framework
        # We can try to remove them if they are listed as " in Frameworks"
        # Be careful not to match the extensions' own build phases, only the main app's.
        # Since we are removing lines, we risk affecting other targets. 
        # BUT, the extensions themselves are being excluded from the build by removing dependencies,
        # so even if we break the extensions' build phases, it doesn't matter for the Main App Release build.
        # So we can aggressively remove these frameworks references.
        
        echo "   Removing Framework references..."
        sed -i.bak '/DeviceActivity\.framework in Frameworks/d' "$PROJECT_FILE"
        sed -i.bak '/ManagedSettings\.framework in Frameworks/d' "$PROJECT_FILE"
        sed -i.bak '/ManagedSettingsUI\.framework in Frameworks/d' "$PROJECT_FILE"
        sed -i.bak '/FamilyControls\.framework in Frameworks/d' "$PROJECT_FILE"

        # Clean up sed backup files
        rm -f "$PROJECT_FILE.bak"

        echo "✅ Project file patched."
    else
        echo "⚠️  ERROR: project.pbxproj file not found!"
        exit 1
    fi

    echo "✅ Successfully removed App Blocking components for Release build"
else
    echo "🛠️  Debug build detected - keeping App Blocking extensions"
fi

echo "✨ CI Post-Clone Script Completed"
exit 0
