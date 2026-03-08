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

# Test if x3f_extract can run (macOS Gatekeeper may block unsigned binaries)
echo "Testing x3f_extract..."
"$RESOURCE_DEST/bin/x3f_extract" 2>/dev/null
EXIT_CODE=$?
# x3f_extract exits 0 or 1 normally (usage); signal-killed = 128 + signal (e.g. SIGKILL=137)
if [ $EXIT_CODE -ge 128 ]; then
    echo ""
    echo "WARNING: x3f_extract was blocked by macOS security."
    echo "警告: macOS のセキュリティによって x3f_extract がブロックされました。"
    echo ""
    echo "Please allow it manually:"
    echo "手動で許可してください:"
    echo "  1. Open: System Settings > Privacy & Security"
    echo "     システム設定 > プライバシーとセキュリティ を開く"
    echo "  2. Scroll down to the Security section"
    echo "     「セキュリティ」セクションまでスクロール"
    echo "  3. Click 'Allow Anyway' next to x3f_extract"
    echo "     x3f_extract の横にある「このまま許可」をクリック"
    echo "  4. Run this script again to verify"
    echo "     このスクリプトを再実行して確認"
else
    echo "x3f_extract OK"
fi
