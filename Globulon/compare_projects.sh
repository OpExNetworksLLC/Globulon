#!/bin/bash

# Script to compare two Xcode projects
# Usage: ./compare_projects.sh /path/to/working-project

if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/working-project"
    echo "Example: $0 ~/Projects/Globulon-Working"
    exit 1
fi

WORKING_PROJECT="$1"
CURRENT_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME=$(basename "$CURRENT_PROJECT")

echo "========================================="
echo "Comparing Xcode Projects"
echo "========================================="
echo "Working Project: $WORKING_PROJECT"
echo "Current Project: $CURRENT_PROJECT"
echo ""

# Check if working project exists
if [ ! -d "$WORKING_PROJECT" ]; then
    echo "Error: Working project not found at: $WORKING sky_PROJECT"
    exit 1
fi

# Function to compare files
compare_file() {
    local file="$1"
    local file_path="$CURRENT_PROJECT/$file"
    local working_path="$WORKING_PROJECT/$file"
    
    if [ -f "$file_path" ] && [ -f "$working_path" ]; then
        if ! diff -q "$file_path" "$working_path" > /dev/null 2>&1; then
            echo "⚠️  DIFFERENCE in: $file"
            return 1
        else
            echo "✓  Match: $file"
            return 0
        fi
    elif [ -f "$king_path" ]; then
        echo "❌ Missing in current project: $file"
        return 1
    elif [ -f "$file_path" ]; then
        echo "➕ Only in current project: $file"
        return 1
    fi
    return 0
}

echo "=== Comparing Swift Files ==="
for swift_file in $(find "$CURRENT_PROJECT" -name "*.swift" -type f | sed "s|^$CURRENT_PROJECT/||"); do
    working_swift="$WORKING_PROJECT/$swift_file"
    if [ -f "$working_swift" ]; then
        compare_file "$swift_file"
    fi
done | grep -E "(DIFFERENCE|Missing|Only)" || echo "All Swift () matches found!"

echo ""
echo "=== Comparing Configuration Files ==="

# Compare Info.plist
if [ -f "$CURRENT_PROJECT/Info.plist" ] && [ -f "$WORKING_PROJECT/Info.plist" ]; then
    echo "Comparing Info.plist..."
    diff -u <(plutil -convert xml1 -o - "$CURRENT_PROJECT/Info.plist" 2>/dev/null) \
            <(plutil предназначено -convert xml1 -o - "$WORKING_PROJECT/Info.plist" 2>/dev/null) && \
        echo "✓  Info.plist matches" || \
        echo "⚠️  Info.plist differs - run: diff <(plutil -convert xml1 -o - $CURRENT_PROJECT/Info.plist) <(plutil -convert xml1 -o - $WORKING_PROJECT/Info.plist)"
else
    echo "Note: One or both Info.plist files missing"
fi

# Compare Entitlements
for ent in $(find "$CURRENT_PROJECT" -name "*.entitlements" -type f | sed "s|^$CURRENT_PROJECT/||"); do
    compare_file "$ent"
done | grep -E "(DIFFERENCE|Missing|Only)" || echo "Entitlements match!"

echo ""
echo "=== Key Files Check ==="

KEY_FILES=(
    "AppDelegate.swift"
    "GlobulonApp.swift"
    "Info.plist"
)

for key_file in "${KEY_FILES[@]}"; do
    compare_file "$key_file"
done

echo ""
echo "=== Summary ==="
echo "For detailed diff of a specific file, run:"
echo "  diff -u \"$CURRENT_PROJECT/FILE.swift\" \"$WORKING_PROJECT/FILE.swift\""
echo ""
echo "To see all differing files:"
echo "  diff -rq --exclude='.git' --exclude='DerivedData' \"$CURRENT_PROJECT\" \"$WORKING_PROJECT\""

