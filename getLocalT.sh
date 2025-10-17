#!/bin/bash

# Localtonet Install Script with Error Handling
# Description: Download and install localtonet securely

set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root user"
    fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    # Check if system is supported
    local os_type
    os_type=$(uname -s)
    if [[ "$os_type" != "Linux" && "$os_type" != "Darwin" ]]; then
        log_error "Unsupported operating system: $os_type"
        exit 1
    fi
    
    log_success "System requirements check passed"
}

# Download and verify the install script
download_install_script() {
    local install_url="https://localtonet.com/install.sh"
    local temp_script="/tmp/localtonet_install_$$.sh"
    
    log_info "Downloading localtonet install script..."
    
    # Download with timeout and retry logic
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -fsSL --connect-timeout 30 --max-time 60 "$install_url" -o "$temp_script"; then
            break
        else
            retry_count=$((retry_count + 1))
            log_warning "Download attempt $retry_count failed, retrying..."
            sleep 2
        fi
    done
    
    if [[ $retry_count -eq $max_retries ]]; then
        log_error "Failed to download install script after $max_retries attempts"
        exit 1
    fi
    
    # Verify the downloaded script
    if [[ ! -s "$temp_script" ]]; then
        log_error "Downloaded script is empty or invalid"
        rm -f "$temp_script"
        exit 1
    fi
    
    # Check if script appears to be a valid bash script
    if ! head -n 5 "$temp_script" | grep -q -E "^(#!|#!/bin/bash|#!/bin/sh)"; then
        log_error "Downloaded file doesn't appear to be a valid shell script"
        rm -f "$temp_script"
        exit 1
    fi
    
    log_success "Install script downloaded successfully"
    echo "$temp_script"
}

# Review the script before execution
review_script() {
    local script_path="$1"
    
    log_info "Reviewing install script..."
    
    # Check script size
    local script_size
    script_size=$(wc -c < "$script_path")
    if [[ $script_size -gt 1000000 ]]; then
        log_warning "Install script is unusually large: $script_size bytes"
    fi
    
    # Show first few lines for review
    log_info "First 10 lines of the install script:"
    head -n 10 "$script_path"
    
    # Ask for user confirmation (optional - remove if you want automatic execution)
    if [[ ${AUTO_CONFIRM:-0} -ne 1 ]]; then
        echo
        read -p "Do you want to continue with the installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            rm -f "$script_path"
            exit 0
        fi
    fi
}

# Execute the install script
execute_install_script() {
    local script_path="$1"
    
    log_info "Executing localtonet install script..."
    
    # Make script executable
    if ! chmod +x "$script_path"; then
        log_error "Failed to make script executable"
        rm -f "$script_path"
        exit 1
    fi
    
    # Execute the script
    if bash "$script_path"; then
        log_success "Localtonet installation completed successfully"
    else
        log_error "Localtonet installation failed"
        rm -f "$script_path"
        exit 1
    fi
    
    # Clean up
    rm -f "$script_path"
}

# Main installation function
main() {
    log_info "Starting Localtonet installation process..."
    
    # Trap to clean up on exit
    trap 'rm -f /tmp/localtonet_install_*.sh 2>/dev/null' EXIT
    
    check_root
    check_requirements
    
    local install_script
    install_script=$(download_install_script)
    
    review_script "$install_script"
    execute_install_script "$install_script"
    
    log_success "Localtonet installation process completed!"
    
    # Additional information
    echo
    log_info "Next steps:"
    log_info "1. Configure localtonet with your preferences"
    log_info "2. Start the localtonet service"
    log_info "3. Visit https://localtonet.com for documentation"
}

# Help function
show_help() {
    cat << EOF
Localtonet Install Script

Usage: $0 [OPTIONS]

Options:
    -y, --auto-confirm    Skip confirmation prompts
    -h, --help           Show this help message

Environment Variables:
    AUTO_CONFIRM=1       Skip confirmation prompts

Examples:
    $0                    # Interactive installation
    $0 --auto-confirm     # Non-interactive installation
    AUTO_CONFIRM=1 $0     # Non-interactive installation
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--auto-confirm)
            AUTO_CONFIRM=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
