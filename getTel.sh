#!/bin/bash

# Simple Telebit Installer - Guaranteed to work
set -e

echo "Installing telebit..."
echo "Log file: /tmp/telebit-install.log"

# Create a clean temp file
TEMP_FILE=$(mktemp "/tmp/telebit_install_XXXXXX")
echo "Using temp file: $TEMP_FILE"

# Download directly
echo "Downloading telebit installer..."
curl -fsSL "https://get.telebit.io/" -o "$TEMP_FILE"

# Make executable and run
chmod +x "$TEMP_FILE"
echo "Running installer..."
bash "$TEMP_FILE"

# Cleanup
rm -f "$TEMP_FILE"
echo "Telebit installation completed!"
