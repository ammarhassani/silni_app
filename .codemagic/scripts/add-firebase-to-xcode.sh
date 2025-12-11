#!/bin/bash
set -e

echo "🔧 Adding GoogleService-Info.plist to Xcode project..."

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
PLIST_FILE="GoogleService-Info.plist"

# Check if file is already in project
if grep -q "GoogleService-Info.plist" "$PROJECT_FILE"; then
    echo "✅ GoogleService-Info.plist already in Xcode project"
    exit 0
fi

echo "📝 File not found in project, adding it now..."

# Generate a unique ID for the file reference (using timestamp-based UUID style)
FILE_REF_ID="$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)"
BUILD_FILE_ID="$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)"

echo "Generated IDs: FileRef=$FILE_REF_ID, BuildFile=$BUILD_FILE_ID"

# Create backup
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

# Find the Runner group section and add file reference
# This adds the file reference to the Runner group (where Info.plist lives)
awk -v file_ref_id="$FILE_REF_ID" '
/\/\* Info.plist \*\/ = {isa = PBXFileReference/ {
    print
    getline
    print
    print "\t\t" file_ref_id " /* GoogleService-Info.plist */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.xml; path = \"GoogleService-Info.plist\"; sourceTree = \"<group>\"; };"
    next
}
{ print }
' "$PROJECT_FILE" > "$PROJECT_FILE.tmp"
mv "$PROJECT_FILE.tmp" "$PROJECT_FILE"

# Add to PBXBuildFile section (for Copy Bundle Resources phase)
awk -v build_file_id="$BUILD_FILE_ID" -v file_ref_id="$FILE_REF_ID" '
/\/\* Begin PBXBuildFile section \*\// {
    print
    print "\t\t" build_file_id " /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = " file_ref_id " /* GoogleService-Info.plist */; };"
    next
}
{ print }
' "$PROJECT_FILE" > "$PROJECT_FILE.tmp"
mv "$PROJECT_FILE.tmp" "$PROJECT_FILE"

# Add file to Runner group's children array
awk -v file_ref_id="$FILE_REF_ID" '
/33CC10EC2044A3C60003C045 \/\* Runner \*\/ = {/ {
    print
    in_runner_group = 1
    next
}
in_runner_group && /children = \(/ {
    print
    getline
    print "\t\t\t\t" file_ref_id " /* GoogleService-Info.plist */,"
    in_runner_group = 0
    next
}
{ print }
' "$PROJECT_FILE" > "$PROJECT_FILE.tmp"
mv "$PROJECT_FILE.tmp" "$PROJECT_FILE"

# Add to Resources build phase
awk -v build_file_id="$BUILD_FILE_ID" '
/\/\* Resources \*\/ = {/ {
    in_resources = 1
}
in_resources && /files = \(/ {
    print
    getline
    print "\t\t\t\t" build_file_id " /* GoogleService-Info.plist in Resources */,"
    in_resources = 0
    next
}
{ print }
' "$PROJECT_FILE" > "$PROJECT_FILE.tmp"
mv "$PROJECT_FILE.tmp" "$PROJECT_FILE"

# Verify the changes
if grep -q "GoogleService-Info.plist" "$PROJECT_FILE"; then
    echo "✅ Successfully added GoogleService-Info.plist to Xcode project"
    echo "📋 Changes made:"
    echo "   - Added file reference (ID: $FILE_REF_ID)"
    echo "   - Added build file (ID: $BUILD_FILE_ID)"
    echo "   - Added to Runner group children"
    echo "   - Added to Resources build phase"
    rm -f "$PROJECT_FILE.backup"
else
    echo "❌ Failed to add file, restoring backup"
    mv "$PROJECT_FILE.backup" "$PROJECT_FILE"
    exit 1
fi

echo "✅ Xcode project updated successfully"
