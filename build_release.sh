#!/bin/bash

# CI/CD Build Script for iOS App Template Release

set -e  # Exit on any error

echo "Starting Release Archive Build..."

# Variables
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE_PATH="$PROJECT_DIR/archives/${CI_BRANCH:-local}-$(date +%Y%m%d-%H%M%S).xcarchive"
mkdir -p "$PROJECT_DIR/archives"

# Detect project and scheme
PROJECT_FILE=""
if [[ -d "$PROJECT_DIR/app-template/app-template.xcodeproj" ]]; then
  PROJECT_FILE="$PROJECT_DIR/app-template/app-template.xcodeproj"
elif [[ -d "$PROJECT_DIR/app-template.xcodeproj" ]]; then
  PROJECT_FILE="$PROJECT_DIR/app-template.xcodeproj"
else
  PROJECT_FILE="$(ls -1d "$PROJECT_DIR"/*.xcodeproj 2>/dev/null | head -1)"
fi

if [[ -z "$PROJECT_FILE" ]]; then
  echo "No .xcodeproj found in $PROJECT_DIR"
  exit 1
fi

SCHEME="$(basename "$PROJECT_FILE" .xcodeproj)"

echo "Cleaning project..."
xcodebuild -project "$PROJECT_FILE" -scheme "$SCHEME" -configuration Release clean

echo "Creating archive..."
xcodebuild -project "$PROJECT_FILE" \
           -scheme "$SCHEME" \
           -configuration Release \
           -destination generic/platform=iOS \
           archive \
           -archivePath "$ARCHIVE_PATH"

echo "Archive created at $ARCHIVE_PATH"

# Optional: Export IPA (requires export options plist)
# Uncomment and provide export options plist path
# echo "Exporting IPA..."
# xcodebuild -exportArchive \
#            -archivePath "$ARCHIVE_PATH" \
#            -exportOptionsPlist "$PROJECT_DIR/app-template/exportOptions.plist" \
#            -exportPath "$PROJECT_DIR/archives"

echo "Build script completed successfully."
echo "Archive: $ARCHIVE_PATH"