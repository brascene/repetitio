#!/bin/sh

# Xcode Cloud Post-Clone Script
# This script runs after the repository is cloned but before the build starts
# It removes App Blocking extensions and capabilities for Release/TestFlight builds

set -e

echo "🔍 CI Post-Clone Script Started"
echo "Environment: CI=${CI}"
echo "Configuration: ${CI_XCODE_CONFIGURATION:-Unknown}"
echo "Workspace Path: $CI_PRIMARY_REPOSITORY_PATH"

# 1. Safety check: Ensure we are running in CI
if [ "$CI" != "TRUE" ]; then
    echo "⚠️  Not running in CI environment (CI variable is not TRUE). Skipping script to protect local project."
    exit 0
fi

# 2. Configuration Check
if [ "$CI_XCODE_CONFIGURATION" = "Debug" ]; then
    echo "🛠️  Debug build detected - keeping App Blocking extensions"
    exit 0
fi

echo "📦 Release (or Unknown) build detected in CI - removing App Blocking extensions and capabilities"

# Navigate to project directory
cd "$CI_PRIMARY_REPOSITORY_PATH"

# --- Entitlements Modification using Python ---
echo "🔧 Starting Entitlements Modification..."

# Find all entitlements files recursively
ENTITLEMENTS_FILES=$(find . -name "*.entitlements")

if [ -z "$ENTITLEMENTS_FILES" ]; then
    echo "⚠️  No .entitlements files found!"
else
    echo "   Found entitlement files:"
    echo "$ENTITLEMENTS_FILES"
    
    # Pass the list of files to Python to process
    python3 -c "
import sys
import plistlib
import os

files_str = '''$ENTITLEMENTS_FILES'''
files = [f.strip() for f in files_str.split('\n') if f.strip()]

for file_path in files:
    # Resolve absolute path just in case, though find returns relative to .
    abs_path = os.path.abspath(file_path)
    print(f'   Processing {file_path}...')
    
    try:
        with open(abs_path, 'rb') as f:
            plist = plistlib.load(f)
        
        if 'com.apple.developer.family-controls' in plist:
            print(f'      Removing com.apple.developer.family-controls key')
            del plist['com.apple.developer.family-controls']
            
            with open(abs_path, 'wb') as f:
                plistlib.dump(plist, f)
            print(f'      ✅ Key removed successfully')
        else:
            print(f'      ℹ️ Key not found in plist')
            
    except Exception as e:
        print(f'      ⚠️ Error modifying plist: {e}')
"
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

# --- Firebase Crashlytics dSYM Upload Configuration ---
# Note: The actual upload happens via the Run Script build phase
# This just ensures the necessary tools are available in Xcode Cloud
echo "📦 Firebase Crashlytics configuration ready"

echo "✨ CI Post-Clone Script Completed"
exit 0
