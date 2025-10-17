#!/bin/bash

# Bore installation script using official GitHub releases
set -e

# Configuration
BORE_VERSION="0.6.0"
REPO_URL="https://github.com/ekzhang/bore"

# Detect architecture
detect_architecture() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            echo "x86_64-unknown-linux-musl"
            ;;
        aarch64)
            echo "aarch64-unknown-linux-musl"
            ;;
        armv7l)
            echo "armv7-unknown-linux-musleabihf"
            ;;
        armv6l)
            echo "armv7-unknown-linux-musleabihf"  # Fallback for armv6
            ;;
        *)
            echo "x86_64-unknown-linux-musl"  # Default fallback
            ;;
    esac
}

ARCHITECTURE=$(detect_architecture)
DOWNLOAD_URL="${REPO_URL}/releases/download/v${BORE_VERSION}/bore-v${BORE_VERSION}-${ARCHITECTURE}.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check dependencies
check_dependencies() {
    local deps=("curl" "tar")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep is required but not installed. Please install it first."
            exit 1
        fi
    done
}

# Check if URL exists
check_url_exists() {
    if curl --output /dev/null --silent --head --fail "$1"; then
        return 0
    else
        return 1
    fi
}

# Get available releases from GitHub API
get_available_releases() {
    print_status "Fetching available releases..."
    local api_url="https://api.github.com/repos/ekzhang/bore/releases"
    
    if command -v jq &> /dev/null; then
        curl -s "$api_url" | jq -r '.[] | select(.assets | length > 0) | .tag_name' | head -5
    else
        print_warning "jq not installed, showing latest versions only"
        curl -s "$api_url" | grep -o '"tag_name": *"[^"]*"' | head -5
    fi
}

# Download and install bore
install_bore() {
    local temp_dir
    temp_dir=$(mktemp -d)
    local archive_name="bore-v${BORE_VERSION}-${ARCHITECTURE}.tar.gz"
    local download_path="$temp_dir/$archive_name"
    
    print_status "Architecture detected: $(uname -m)"
    print_status "Using target: $ARCHITECTURE"
    print_status "Download URL: $DOWNLOAD_URL"
    echo
    
    # Check if the download URL exists
    print_status "Checking if download URL is valid..."
    if ! check_url_exists "$DOWNLOAD_URL"; then
        print_error "Download URL not found: $DOWNLOAD_URL"
        print_status "Available releases:"
        get_available_releases
        echo
        print_error "This architecture might not be supported in v${BORE_VERSION}"
        print_status "You can check available releases at: $REPO_URL/releases"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    print_status "Downloading bore v${BORE_VERSION}..."
    if ! curl -L --progress-bar -o "$download_path" "$DOWNLOAD_URL"; then
        print_error "Failed to download bore"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    print_status "Extracting bore..."
    if ! tar -xzf "$download_path" -C "$temp_dir"; then
        print_error "Failed to extract archive"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Check if bore binary was extracted
    if [[ ! -f "$temp_dir/bore" ]]; then
        print_error "Bore binary not found in archive"
        print_status "Contents of archive:"
        tar -tzf "$download_path" || true
        rm -rf "$temp_dir"
        exit 1
    fi
    
    print_status "Installing bore to /usr/local/bin..."
    sudo cp "$temp_dir/bore" /usr/local/bin/
    sudo chmod +x /usr/local/bin/bore
    
    # Clean up
    rm -rf "$temp_dir"
    
    print_status "Verifying installation..."
    if command -v bore &> /dev/null; then
        print_status "bore v${BORE_VERSION} installed successfully!"
        echo
        print_status "Usage examples:"
        echo "  bore local 3000 --to bore.pub"
        echo "  bore local 8080 --to bore.pub --port 9000"
        echo "  bore --help"
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Alternative installation to current directory
install_to_current_dir() {
    local archive_name="bore-v${BORE_VERSION}-${ARCHITECTURE}.tar.gz"
    
    print_status "Architecture detected: $(uname -m)"
    print_status "Using target: $ARCHITECTURE"
    print_status "Download URL: $DOWNLOAD_URL"
    echo
    
    # Check if the download URL exists
    print_status "Checking if download URL is valid..."
    if ! check_url_exists "$DOWNLOAD_URL"; then
        print_error "Download URL not found: $DOWNLOAD_URL"
        print_status "Available releases:"
        get_available_releases
        echo
        print_error "This architecture might not be supported in v${BORE_VERSION}"
        print_status "You can check available releases at: $REPO_URL/releases"
        exit 1
    fi
    
    print_status "Downloading bore v${BORE_VERSION} to current directory..."
    if ! curl -L --progress-bar -o "$archive_name" "$DOWNLOAD_URL"; then
        print_error "Failed to download bore"
        exit 1
    fi
    
    print_status "Extracting bore..."
    if ! tar -xzf "$archive_name"; then
        print_error "Failed to extract archive"
        exit 1
    fi
    
    # Check if bore binary was extracted
    if [[ ! -f "bore" ]]; then
        print_error "Bore binary not found in archive"
        print_status "Contents of archive:"
        tar -tzf "$archive_name" || true
        exit 1
    fi
    
    chmod +x bore
    
    print_status "bore v${BORE_VERSION} extracted to current directory!"
    echo
    print_status "Run with: ./bore"
    echo
    print_status "Usage examples:"
    echo "  ./bore local 3000 --to bore.pub"
    echo "  ./bore local 8080 --to bore.pub --port 9000"
    echo
    print_warning "Note: The tar.gz file can be removed if you want to save space:"
    echo "  rm $archive_name"
}

# Show system information
show_system_info() {
    print_status "System Information:"
    echo "  Architecture: $(uname -m)"
    echo "  OS: $(uname -s)"
    echo "  Detected target: $ARCHITECTURE"
    echo "  Bore version: $BORE_VERSION"
    echo
}

# Main script
main() {
    echo "=== Bore Installation Script ==="
    show_system_info
    
    check_dependencies
    
    echo "Installation options:"
    echo "1) Install system-wide to /usr/local/bin (requires sudo)"
    echo "2) Install to current directory"
    echo "3) Show available releases"
    read -p "Choose option (1, 2, or 3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            install_bore
            ;;
        2)
            install_to_current_dir
            ;;
        3)
            get_available_releases
            echo
            print_status "Run the script again to install"
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
