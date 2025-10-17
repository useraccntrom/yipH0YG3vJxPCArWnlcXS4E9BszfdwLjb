#!/bin/bash

# Metasploit Installation Script
echo "Starting Metasploit Framework installation..."

# Update package list
echo "Step 1: Updating package list..."
sudo apt update

# Install dependencies
echo "Step 2: Installing dependencies..."
sudo apt install gpgv2 autoconf bison build-essential postgresql libaprutil1 libgmp3-dev libpcap-dev openssl libpq-dev libreadline6-dev libsqlite3-dev libssl-dev locate libsvn1 libtool libxml2 libxml2-dev libxslt-dev wget libyaml-dev ncurses-dev postgresql-contrib xsel zlib1g zlib1g-dev curl -y

# Download msfinstall script
echo "Step 3: Downloading Metasploit installer..."
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall

# Make it executable
echo "Step 4: Making installer executable..."
chmod 755 msfinstall

# Run the installer
echo "Step 5: Running Metasploit installer..."
echo "This may take several minutes..."
./msfinstall

echo "Installation complete!"
echo "You can now start Metasploit with: msfconsole"
