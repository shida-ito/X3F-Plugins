#!/bin/bash

# Capture One X3F Plugin Fix Script
# This script installs the plugin and script to the correct locations and clears quarantine flags.

SCRIPT_NAME="X3F Converter.applescript"
# Use the directory where the script is located
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

C1_SCRIPT_DEST="$HOME/Library/Scripts/Capture One Scripts"
RESOURCE_DEST="$C1_SCRIPT_DEST/X3F_Resources"

echo "--- Capture One X3F Script Deployment ---"

# 1. Setup Resource Folder
echo "Installing Resources..."
mkdir -p "$C1_SCRIPT_DEST"
rm -rf "$RESOURCE_DEST"
cp -R "$REPO_DIR/X3F_Resources" "$C1_SCRIPT_DEST/"

# Set permissions
chmod -R 755 "$RESOURCE_DEST"
chmod +x "$RESOURCE_DEST/bin/x3f_extract"
chmod +x "$RESOURCE_DEST/bin/exiftool"
chmod +x "$RESOURCE_DEST/convert.sh"

# Remove quarantine flags
xattr -rd com.apple.quarantine "$RESOURCE_DEST" 2>/dev/null

# Ad-hoc code sign the binaries
# Required for arm64 binaries on Apple Silicon: unsigned arm64 binaries are killed by AMFI
# (unlike x86_64, arm64 requires at minimum an ad-hoc signature to run)
codesign -s - --force "$RESOURCE_DEST/bin/x3f_extract"
codesign -s - --force "$RESOURCE_DEST/bin/exiftool"

# 2. Setup Scripts Menu
echo "Installing Script..."
# Copy the AppleScript source directly
cp "$REPO_DIR/X3F Converter.applescript" "$C1_SCRIPT_DEST/$SCRIPT_NAME"
# Remove quarantine flags from script
xattr -d com.apple.quarantine "$C1_SCRIPT_DEST/$SCRIPT_NAME" 2>/dev/null

echo "Cleaning up legacy files..."
rm -rf "$HOME/Library/Application Support/Capture One/Plug-ins/X3FforC1.c1plugin"

echo "--- Done! ---"
echo "Installation complete."
echo ""

# Verify x3f_extract runs correctly after signing
echo "Testing x3f_extract..."
"$RESOURCE_DEST/bin/x3f_extract" 2>/dev/null
EXIT_CODE=$?
# x3f_extract exits 0 or 1 normally (usage); anything else is unexpected
if [ $EXIT_CODE -ge 128 ]; then
    echo ""
    echo "ERROR: x3f_extract failed to run (exit $EXIT_CODE)."
    echo "エラー: x3f_extract が起動できませんでした (終了コード $EXIT_CODE)。"
    echo "Try rebuilding the binary: cd x3f_source/src && make"
else
    echo "x3f_extract OK"
fi
