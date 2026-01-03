#!/bin/bash
set -euo pipefail

# Universal Ethernet/Wi-Fi Auto Switcher for Linux
# This script is self-contained and includes the switcher logic and uninstaller.

DEFAULT_INSTALL_DIR="/usr/local/bin"
SERVICE_NAME="eth-wifi-auto"

# Embedded components (Base64)
SWITCHER_B64="__SWITCHER_B64__"
UNINSTALLER_B64="__UNINSTALLER_B64__"

install() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root (sudo)"
        exit 1
    fi

    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    if [[ -t 0 ]]; then
        read -p "Enter installation directory [$DEFAULT_INSTALL_DIR]: " input_dir
        INSTALL_DIR=${input_dir:-$DEFAULT_INSTALL_DIR}
    fi

    echo "Installing Ethernet/Wi-Fi Auto Switcher to $INSTALL_DIR..."

    mkdir -p "$INSTALL_DIR"

    # Extract switcher
    echo "$SWITCHER_B64" | base64 -d > "$INSTALL_DIR/eth-wifi-auto.sh"
    chmod +x "$INSTALL_DIR/eth-wifi-auto.sh"

    # Create systemd service
    cat <<EOF > "/etc/systemd/system/$SERVICE_NAME.service"
[Unit]
Description=Ethernet/Wi-Fi Auto Switcher
After=network.target

[Service]
ExecStart=$INSTALL_DIR/eth-wifi-auto.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"

    echo "Installation complete. Service is running."
}

uninstall() {
    echo "$UNINSTALLER_B64" | base64 -d | bash
}

if [[ "${1:-}" == "--uninstall" ]]; then
    uninstall
else
    install
fi
