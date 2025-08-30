#!/bin/bash

# SetiAstroSuite Auto-Updater Script for mac apple silicon
# This script automatically downloads and installs the latest version of SetiAstroSuite

set -e  # Exit on any error

# Configuration - change it to your target directory
TARGET_DIR="/Volumes/T7/astroapp"
APP_NAME="setiastrosuitemac_applesilicon"
TEMP_DIR="/tmp/setiastrosuite_update"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if T7 drive is mounted
check_t7_mounted() {
    if [ ! -d "$TARGET_DIR" ]; then
        print_error "T7 drive is not mounted or directory $TARGET_DIR does not exist"
        print_status "Please ensure your T7 drive is connected and mounted"
        exit 1
    fi
    print_success "T7 drive is mounted and accessible"
}

# Function to create target directory if it doesn't exist
create_target_directory() {
    if [ ! -d "$TARGET_DIR" ]; then
        print_status "Creating target directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    fi
}

# Function to get the latest release download URL
get_latest_release_url() {
    # Use GitHub REST API to get the latest release
    API_URL="https://api.github.com/repos/setiastro/setiastrosuite/releases/latest"
    
    # Get the latest release info from GitHub API with proper headers
    RELEASE_INFO=$(curl -s -H "Accept: application/vnd.github.v3+json" "$API_URL")
    
    if [ $? -ne 0 ]; then
        print_error "Failed to fetch release information from GitHub API"
        exit 1
    fi
    
    # Check if we got valid JSON response
    if ! echo "$RELEASE_INFO" | grep -q '"tag_name"'; then
        # Check for rate limiting
        if echo "$RELEASE_INFO" | grep -q "API rate limit exceeded"; then
            print_error "GitHub API rate limit exceeded. Please try again later."
            exit 1
        fi
        
        print_error "Invalid response from GitHub API"
        print_status "Response: $RELEASE_INFO"
        exit 1
    fi
    
    # Extract the tag name for display
    TAG_NAME=$(echo "$RELEASE_INFO" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data['tag_name'])" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$TAG_NAME" ]; then
        print_status "Latest release: $TAG_NAME" >&2
    else
        print_warning "Could not extract tag name, continuing..." >&2
    fi
    
    # Find the setiastrosuite_mac.tar.gz asset using Python for reliable JSON parsing
    LATEST_URL=$(echo "$RELEASE_INFO" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for asset in data['assets']:
        if asset['name'] == 'setiastrosuite_mac.tar.gz':
            print(asset['browser_download_url'])
            break
except Exception as e:
    sys.exit(1)
" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$LATEST_URL" ]; then
        print_error "Could not find setiastrosuite_mac.tar.gz in the latest release" >&2
        print_status "Available assets:" >&2
        echo "$RELEASE_INFO" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for asset in data['assets']:
        print(f'- {asset[\"name\"]}: {asset[\"browser_download_url\"]}')
except Exception as e:
    print(f'Error parsing assets: {e}')
" 2>/dev/null >&2
        exit 1
    fi
    
    print_success "Found download URL: $LATEST_URL" >&2
    # Return the URL without newline
    echo -n "$LATEST_URL"
}

# Function to download and extract the archive
download_and_extract() {
    local download_url="$1"
    
    # Create temporary directory
    print_status "Creating temporary directory: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Download the archive
    print_status "Downloading SetiAstroSuite..."
    if curl -L -o "setiastrosuite_mac.tar.gz" "$download_url"; then
        print_success "Download completed successfully"
    else
        print_error "Download failed"
        exit 1
    fi
    
    # Extract the archive
    print_status "Extracting archive..."
    if tar -xzf "setiastrosuite_mac.tar.gz"; then
        print_success "Archive extracted successfully"
    else
        print_error "Failed to extract archive"
        exit 1
    fi
    
    # Check if the app file exists
    if [ ! -f "$APP_NAME" ]; then
        print_error "Could not find $APP_NAME in the extracted archive"
        print_status "Contents of extracted directory:"
        ls -la
        exit 1
    fi
    
    print_success "Found $APP_NAME in extracted archive"
}

# Function to install the app
install_app() {
    # Remove old version if it exists
    if [ -f "$TARGET_DIR/$APP_NAME" ]; then
        print_status "Removing old version..."
        rm -f "$TARGET_DIR/$APP_NAME"
    fi
    
    # Copy new version
    print_status "Installing new version to $TARGET_DIR..."
    if cp "$APP_NAME" "$TARGET_DIR/"; then
        print_success "App copied successfully"
    else
        print_error "Failed to copy app to target directory"
        exit 1
    fi
    
    # Make executable
    chmod +x "$TARGET_DIR/$APP_NAME"
    print_success "App permissions set correctly"
}

# Function to clear quarantine attributes
clear_quarantine() {
    print_status "Clearing quarantine attributes..."
    if sudo xattr -rd com.apple.quarantine "$TARGET_DIR/$APP_NAME"; then
        print_success "Quarantine attributes cleared successfully"
    else
        print_warning "Failed to clear quarantine attributes (this might be normal if no quarantine attributes were present)"
    fi
}

# Function to cleanup temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    print_success "Cleanup completed"
}

# Function to verify installation
verify_installation() {
    if [ -f "$TARGET_DIR/$APP_NAME" ] && [ -x "$TARGET_DIR/$APP_NAME" ]; then
        print_success "Installation verified successfully!"
        print_status "SetiAstroSuite is now available at: $TARGET_DIR/$APP_NAME"
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting SetiAstroSuite auto-update process..."
    
    # Check prerequisites
    check_t7_mounted
    create_target_directory
    
    # Get latest release URL
    print_status "Fetching latest release information from GitHub API..."
    local download_url=$(get_latest_release_url)
    
    # Debug: show the URL being used
    print_status "Using download URL: $download_url"
    
    # Download and extract
    download_and_extract "$download_url"
    
    # Install
    install_app
    
    # Clear quarantine
    clear_quarantine
    
    # Verify installation
    verify_installation
    
    # Cleanup
    cleanup
    
    print_success "SetiAstroSuite update completed successfully!"
}

# Handle script interruption
trap 'print_error "Script interrupted. Cleaning up..."; cleanup; exit 1' INT TERM

# Run main function
main "$@"
