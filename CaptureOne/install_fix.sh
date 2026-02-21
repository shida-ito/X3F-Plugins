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
rm -rf "$RESOURCE_DEST"
cp -R "$REPO_DIR/X3F_Resources" "$C1_SCRIPT_DEST/"

# Set permissions
chmod -R 755 "$RESOURCE_DEST"
chmod +x "$RESOURCE_DEST/bin/x3f_extract"
chmod +x "$RESOURCE_DEST/bin/exiftool"
chmod +x "$RESOURCE_DEST/convert.sh"

# Remove quarantine flags
xattr -rd com.apple.quarantine "$RESOURCE_DEST" 2>/dev/null

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
