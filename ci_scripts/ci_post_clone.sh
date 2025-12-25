#!/bin/sh

# Xcode Cloud Post-Clone Script
# This script runs after the repository is cloned but before the build starts
# It removes App Blocking extensions and capabilities for Release/TestFlight builds

set -e

echo "🔍 CI Post-Clone Script Started"
echo "Configuration: ${CI_XCODE_CONFIGURATION:-Unknown}"
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

    # --- Entitlements Modification using Python ---
    ENTITLEMENTS_FILE=$(find . -name "YRepeat.entitlements" -print -quit)
    if [ -n "$ENTITLEMENTS_FILE" ]; then
        echo "🔧 Found entitlements at: $ENTITLEMENTS_FILE"
        echo "   Content before modification:"
        cat "$ENTITLEMENTS_FILE"

        python3 -c "
import sys
import plistlib

file_path = '$ENTITLEMENTS_FILE'
try:
    with open(file_path, 'rb') as f:
        plist = plistlib.load(f)
    
    if 'com.apple.developer.family-controls' in plist:
        print('   Removing com.apple.developer.family-controls key')
        del plist['com.apple.developer.family-controls']
        
        with open(file_path, 'wb') as f:
            plistlib.dump(plist, f)
        print('   ✅ Key removed successfully')
    else:
        print('   ℹ️ Key not found in plist')

except Exception as e:
    print(f'   ⚠️ Error modifying plist: {e}')
    sys.exit(1)
"
        echo "   Content after modification:"
        cat "$ENTITLEMENTS_FILE"
    else
        echo "⚠️  ERROR: YRepeat.entitlements file not found!"
        exit 1
    fi

    # --- Project File Modification using Python ---
    PROJECT_FILE=$(find . -name "project.pbxproj" -path "*/YRepeat.xcodeproj/*" -print -quit)
    
    if [ -n "$PROJECT_FILE" ]; then
        echo "🔧 Found project file at: $PROJECT_FILE"
        cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

        # Python script to robustly modify the project file
        python3 -c "
import sys
import re

file_path = '$PROJECT_FILE'
with open(file_path, 'r') as f:
    content = f.read()

print(f'Original content length: {len(content)}')

# 1. Remove Target Dependencies from Main App
content = re.sub(r'\s+C4217B392EFC488200BEE804 /\* PBXTargetDependency \*/,', '', content)
content = re.sub(r'\s+C4217B532EFC4C3700BEE804 /\* PBXTargetDependency \*/,', '', content)

# 2. Remove Extensions from 'Embed Foundation Extensions' phase
content = re.sub(r'.*YRepeatDeviceActivityMonitor\.appex in Embed Foundation Extensions.*', '', content)
content = re.sub(r'.*YRepeatShieldConfiguration\.appex in Embed Foundation Extensions.*', '', content)

# 3. Remove Targets from PBXProject 'targets' list
content = re.sub(r'\s+C4217B2E2EFC488200BEE804 /\* YRepeatDeviceActivityMonitor \*/,', '', content)
content = re.sub(r'\s+C4217B472EFC4C3600BEE804 /\* YRepeatShieldConfiguration \*/,', '', content)

# 4. Remove Frameworks
content = re.sub(r'.*DeviceActivity\.framework in Frameworks.*', '', content)
content = re.sub(r'.*ManagedSettings\.framework in Frameworks.*', '', content)
content = re.sub(r'.*ManagedSettingsUI\.framework in Frameworks.*', '', content)
content = re.sub(r'.*FamilyControls\.framework in Frameworks.*', '', content)

print(f'Modified content length: {len(content)}')

with open(file_path, 'w') as f:
    f.write(content)
"
        echo "✅ Project file patched using Python."
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
