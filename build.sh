#!/bin/bash
set -euo pipefail

# =========================================================
# Universal Ethernet/Wi-Fi Auto Switcher - Build Coordinator
# =========================================================

DIST_DIR="dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "🚀 Starting multi-platform build..."

# 1. macOS
if [[ -f "src/macos/build-macos.sh" ]]; then
    bash src/macos/build-macos.sh
else
    echo "⚠️ macOS build script not found."
fi

# 2. Linux
if [[ -f "src/linux/build-linux.sh" ]]; then
    bash src/linux/build-linux.sh
else
    echo "⚠️ Linux build script not found."
fi

# 3. Windows
if [[ -f "src/windows/build-windows.sh" ]]; then
    bash src/windows/build-windows.sh
else
    echo "⚠️ Windows build script not found."
fi

echo ""
echo "🎉 All builds complete! Artifacts are in ./$DIST_DIR"
ls -l "$DIST_DIR"
