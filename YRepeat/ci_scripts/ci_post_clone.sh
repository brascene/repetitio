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
    echo "🔧 Starting Entitlements Modification..."
    python3 -c "
import sys
import plistlib
import os

# List of entitlement files to modify
entitlement_files = [
    'YRepeat/YRepeat.entitlements',
    'YRepeatDeviceActivityMonitor/YRepeatDeviceActivityMonitor.entitlements',
    'YRepeatShieldConfiguration/YRepeatShieldConfiguration.entitlements'
]

for file_rel_path in entitlement_files:
    file_path = os.path.abspath(file_rel_path)
    if os.path.exists(file_path):
        print(f'   Processing {file_rel_path}...')
        try:
            with open(file_path, 'rb') as f:
                plist = plistlib.load(f)
            
            if 'com.apple.developer.family-controls' in plist:
                print(f'      Removing com.apple.developer.family-controls key')
                del plist['com.apple.developer.family-controls']
                
                with open(file_path, 'wb') as f:
                    plistlib.dump(plist, f)
                print(f'      ✅ Key removed successfully')
            else:
                print(f'      ℹ️ Key not found in plist')
        except Exception as e:
            print(f'      ⚠️ Error modifying plist: {e}')
            # We don't exit here, we try to process other files
    else:
        print(f'   ⚠️ File not found: {file_rel_path}')
"

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

print(f'   Original content length: {len(content)}')

def remove_pattern(pattern, name, content):
    content, count = re.subn(pattern, '', content)
    if count > 0:
        print(f'      ✅ Removed {count} occurrences of {name}')
    else:
        print(f'      ⚠️ Did not find pattern for {name}')
    return content

# 1. Remove Target Dependencies from Main App (ID based)
content = remove_pattern(r'\s+C4217B392EFC488200BEE804 /\* PBXTargetDependency \*/,', 'DeviceActivityMonitor Dependency', content)
content = remove_pattern(r'\s+C4217B532EFC4C3700BEE804 /\* PBXTargetDependency \*/,', 'ShieldConfiguration Dependency', content)

# 2. Remove Extensions from 'Embed Foundation Extensions' phase (Pattern based)
content = remove_pattern(r'\s+[A-F0-9]+ /\* YRepeatDeviceActivityMonitor\.appex in Embed Foundation Extensions \*/,', 'DeviceActivityMonitor Embed', content)
content = remove_pattern(r'\s+[A-F0-9]+ /\* YRepeatShieldConfiguration\.appex in Embed Foundation Extensions \*/,', 'ShieldConfiguration Embed', content)

# 3. Remove Targets from PBXProject 'targets' list (ID based)
content = remove_pattern(r'\s+C4217B2E2EFC488200BEE804 /\* YRepeatDeviceActivityMonitor \*/,', 'DeviceActivityMonitor Target', content)
content = remove_pattern(r'\s+C4217B472EFC4C3600BEE804 /\* YRepeatShieldConfiguration \*/,', 'ShieldConfiguration Target', content)

# 4. Remove Frameworks (Pattern based)
content = remove_pattern(r'\s+[A-F0-9]+ /\* DeviceActivity\.framework in Frameworks \*/,', 'DeviceActivity Framework', content)
content = remove_pattern(r'\s+[A-F0-9]+ /\* ManagedSettings\.framework in Frameworks \*/,', 'ManagedSettings Framework', content)
content = remove_pattern(r'\s+[A-F0-9]+ /\* ManagedSettingsUI\.framework in Frameworks \*/,', 'ManagedSettingsUI Framework', content)
# FamilyControls might not be explicitly linked if implicit, but removing if present
content = remove_pattern(r'\s+[A-F0-9]+ /\* FamilyControls\.framework in Frameworks \*/,', 'FamilyControls Framework', content)

print(f'   Modified content length: {len(content)}')

with open(file_path, 'w') as f:
    f.write(content)
"
        echo "✅ Project file patched using Python."
    else
        echo "⚠️  ERROR: project.pbxproj file not found!"
        exit 1
    fi

    echo "✅ Successfully processed App Blocking components for Release build"
else
    echo "🛠️  Debug build detected - keeping App Blocking extensions"
fi

echo "✨ CI Post-Clone Script Completed"
exit 0

