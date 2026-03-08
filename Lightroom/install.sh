#!/bin/bash

# Lightroom X3F Plugin Install Script
# This script removes quarantine flags and applies ad-hoc code signing
# to allow the bundled binaries to run on Apple Silicon (macOS Sequoia and later).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/X3FforLrC.lrplugin"
BIN_DIR="$PLUGIN_DIR/bin"

echo "--- Lightroom X3F Plugin Setup ---"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "ERROR: X3FforLrC.lrplugin not found in $SCRIPT_DIR"
    exit 1
fi

# Remove quarantine flags
echo "Removing quarantine flags..."
xattr -dr com.apple.quarantine "$PLUGIN_DIR" 2>/dev/null

# Ad-hoc code sign the binaries
# Required for arm64 binaries on Apple Silicon: unsigned arm64 binaries are killed by AMFI
# (unlike x86_64, arm64 requires at minimum an ad-hoc signature to run)
echo "Signing binaries..."
codesign -s - --force "$BIN_DIR/x3f_extract"
codesign -s - --force "$BIN_DIR/exiftool"

echo "--- Done! ---"
echo ""

# Verify x3f_extract runs correctly after signing
echo "Testing x3f_extract..."
"$BIN_DIR/x3f_extract" 2>/dev/null
EXIT_CODE=$?
# x3f_extract exits 0 or 1 normally (usage); anything else is unexpected
if [ $EXIT_CODE -ge 128 ]; then
    echo ""
    echo "ERROR: x3f_extract failed to run (exit $EXIT_CODE)."
    echo "エラー: x3f_extract が起動できませんでした (終了コード $EXIT_CODE)。"
    echo "The binary may be corrupted. Please obtain a new copy and run this script again."
    echo "バイナリが破損している可能性があります。最新版を入手してこのスクリプトを再実行してください。"
    exit 1
else
    echo "x3f_extract OK"
fi

echo ""
echo "Installation complete."
echo "インストール完了。"
echo ""
echo "Next steps / 次のステップ:"
echo "  1. Open Lightroom Classic / Lightroom Classic を起動"
echo "  2. File > Plug-in Manager / ファイル > プラグインマネージャー"
echo "  3. Click 'Add' and select: $PLUGIN_DIR"
echo "     「追加」をクリックして選択: $PLUGIN_DIR"
