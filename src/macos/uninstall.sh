#!/bin/bash
set -euo pipefail

# These will be set by the installer
SYS_PLIST_PATH="SYS_PLIST_PATH_PLACEHOLDER"
SYS_HELPER_PATH="SYS_HELPER_PATH_PLACEHOLDER"
SYS_WATCHER_BIN="SYS_WATCHER_BIN_PLACEHOLDER"
WORKDIR="WORKDIR_PLACEHOLDER"

echo "Stopping LaunchDaemon..."
sudo launchctl bootout system "$SYS_PLIST_PATH" 2>/dev/null || true

echo "Removing system files..."
sudo rm -f "$SYS_PLIST_PATH" "$SYS_HELPER_PATH" "$SYS_WATCHER_BIN"

echo "Removing workspace..."
sudo rm -rf "$WORKDIR"

echo "✅ Uninstalled completely."
