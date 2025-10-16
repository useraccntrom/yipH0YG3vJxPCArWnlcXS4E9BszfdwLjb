#!/bin/bash

# localtonet Auto-Install Script for Windows
# This script downloads, installs, and starts localtonet with your API token

set -e  # Exit on any error

# Configuration
API_TOKEN=""
INSTALL_URL="https://localtonet.com/install.sh"
SCRIPT_DIR="/tmp/localtonet_setup"
LOG_FILE="$SCRIPT_DIR/installation.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function for colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create working directory
mkdir -p "$SCRIPT_DIR"
cd "$SCRIPT_DIR"

# Function to check if running on Windows (WSL/Cygwin/Git Bash)
check_windows_environment() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || grep -q Microsoft /proc/version 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to download and install localtonet
install_localtonet() {
    print_status "Downloading localtonet installation script..."
    
    if curl -fsSL "$INSTALL_URL" -o "install.sh"; then
        print_status "Download completed successfully"
    else
        print_error "Failed to download installation script"
        exit 1
    fi
    
    print_status "Making installation script executable..."
    chmod +x install.sh
    
    print_status "Running localtonet installation..."
    ./install.sh
    
    if [ $? -eq 0 ]; then
        print_status "Installation completed successfully"
    else
        print_error "Installation failed"
        exit 1
    fi
}

# Function to start localtonet with the API token
start_localtonet() {
    print_status "Starting localtonet with provided token..."
    
    # Try different possible command names
    localtonet_cmds=("localtonet" "lt" "localtonet.exe" "lt.exe")
    
    for cmd in "${localtonet_cmds[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            print_status "Found localtonet command: $cmd"
            LOCALTONET_CMD="$cmd"
            break
        fi
    done
    
    if [ -z "$LOCALTONET_CMD" ]; then
        print_warning "localtonet command not found in PATH, checking common locations..."
        
        # Check common installation directories
        common_paths=(
            "/usr/local/bin/localtonet"
            "/usr/bin/localtonet"
            "$HOME/.local/bin/localtonet"
            "/opt/localtonet/localtonet"
            "/c/Program Files/localtonet/localtonet.exe"
            "/c/Users/$USER/AppData/Local/Programs/localtonet/localtonet.exe"
        )
        
        for path in "${common_paths[@]}"; do
            if [ -f "$path" ]; then
                LOCALTONET_CMD="$path"
                print_status "Found localtonet at: $path"
                break
            fi
        done
    fi
    
    if [ -z "$LOCALTONET_CMD" ]; then
        print_error "Could not find localtonet executable. Please check if installation was successful."
        exit 1
    fi
    
    print_status "Starting localtonet with token: ${API_TOKEN:0:8}..."  # Show only first 8 chars for security
    
    # Start localtonet in background
    if "$LOCALTONET_CMD" authtoken "$API_TOKEN"; then
        print_status "Authentication successful"
    else
        print_error "Authentication failed"
        exit 1
    fi
    
    # Start the service
    print_status "Starting localtonet service..."
    "$LOCALTONET_CMD" start --background
    
    if [ $? -eq 0 ]; then
        print_status "localtonet started successfully in background"
    else
        print_error "Failed to start localtonet"
        exit 1
    fi
}

# Function to check if localtonet is running
check_status() {
    print_status "Checking localtonet status..."
    sleep 3
    
    for cmd in "localtonet" "lt" "localtonet.exe" "lt.exe"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            if "$cmd" status 2>/dev/null | grep -q "running"; then
                print_status "localtonet is running successfully!"
                return 0
            fi
        fi
    done
    
    print_warning "Could not verify running status automatically, but startup was initiated"
    return 1
}

# Function to create a startup script for Windows
create_startup_script() {
    local startup_script="$SCRIPT_DIR/start_localtonet.bat"
    
    print_status "Creating Windows startup script..."
    
    cat > "$startup_script" << EOF
@echo off
echo Starting localtonet...
localtonet authtoken $API_TOKEN
localtonet start
pause
EOF

    print_status "Startup script created at: $startup_script"
}

# Main execution
main() {
    print_status "Starting localtonet automated setup..."
    print_status "API Token: ${API_TOKEN:0:8}..."  # Show only first 8 chars
    
    # Check if we're in a Windows environment
    if check_windows_environment; then
        print_status "Detected Windows environment"
    else
        print_warning "This script is designed for Windows environments (WSL, Cygwin, Git Bash)"
        print_warning "Proceeding anyway..."
    fi
    
    # Install localtonet
    install_localtonet
    
    # Start localtonet with token
    start_localtonet
    
    # Check status
    check_status
    
    # Create startup script for future use
    create_startup_script
    
    print_status "Setup completed!"
    print_status "You can use the generated BAT file to start localtonet in the future."
    print_status "Check $LOG_FILE for detailed logs."
}

# Run main function and log output
main 2>&1 | tee "$LOG_FILE"
