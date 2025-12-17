#!/usr/bin/env bash
# Installation script for Clyde CLI
# Supports macOS and Linux
#
# Environment variables:
#   GITHUB_TOKEN - Required. GitHub personal access token for private repo access
#   CLYDE_VERSION - Install specific version (e.g., "1.0.2"). Default: latest
#   INSTALL_DEPENDENCIES - If "true", runs "clyde install all" after installation
set -euo pipefail

# Configuration
GITHUB_REPO="OutSystems/dx-claude-code-marketplace"
INSTALL_DIR="$HOME/.local/bin"

# Colors for output
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin)
            echo "darwin"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            log_error "Unsupported operating system: $(uname -s)"
            ;;
    esac
}

# Detect architecture
detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            ;;
    esac
}

# Ensure ~/.local/bin exists and is in PATH
setup_local_bin() {
    local bin_dir="$INSTALL_DIR"

    if [[ ! -d "$bin_dir" ]]; then
        mkdir -p "$bin_dir"
        log_info "Created $bin_dir"
    fi

    # Add to PATH if not already present
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        export PATH="$bin_dir:$PATH"

        # Add to shell profile for persistence
        local shell_profile=""
        if [[ -n "${BASH_VERSION:-}" ]]; then
            shell_profile="$HOME/.bashrc"
        elif [[ -n "${ZSH_VERSION:-}" ]]; then
            shell_profile="$HOME/.zshrc"
        fi

        if [[ -n "$shell_profile" ]] && [[ -f "$shell_profile" ]]; then
            if ! grep -q "$bin_dir" "$shell_profile"; then
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_profile"
                log_info "Added $bin_dir to PATH in $shell_profile"
            fi
        fi
    fi
}

# Resolve version to install
resolve_version() {
    if [[ -n "${CLYDE_VERSION:-}" ]]; then
        echo "$CLYDE_VERSION"
    else
        # Fetch latest version from GitHub API
        log_info "Fetching latest version..." >&2
        local latest_tag
        latest_tag=$(curl -sH "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | \
            grep '"tag_name"' | cut -d'"' -f4)

        if [[ -z "$latest_tag" ]]; then
            log_error "Failed to fetch latest version. Check your GITHUB_TOKEN permissions."
        fi

        # Remove 'v' prefix to get version number
        echo "${latest_tag#v}"
    fi
}

# Get asset download URL from GitHub API
get_asset_url() {
    local version="$1"
    local os="$2"
    local arch="$3"
    local asset_name="clyde_${os}_${arch}.tar.gz"

    log_info "Fetching asset URL..." >&2

    # Get the release by tag and extract asset ID using grep and sed
    local asset_id
    asset_id=$(curl -sH "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/${GITHUB_REPO}/releases/tags/v${version}" | \
        grep -B 2 "\"name\": \"${asset_name}\"" | \
        grep '"id"' | \
        head -1 | \
        grep -o '[0-9]\+')

    if [[ -z "$asset_id" ]]; then
        log_error "Failed to find asset ${asset_name} in release v${version}"
    fi

    echo "https://api.github.com/repos/${GITHUB_REPO}/releases/assets/${asset_id}"
}

# Install Clyde binary
install_clyde() {
    local os="$1"
    local arch="$2"
    local version="$3"

    # Check if already installed
    if command_exists clyde; then
        local current_version
        current_version=$(clyde version --quiet 2>/dev/null || echo "unknown")
        log_success "Clyde already installed: v$current_version"

        if [[ "$version" != "latest" ]] && [[ "$current_version" != "$version" ]]; then
            log_warning "Installed version (v$current_version) differs from requested version (v$version)"
            log_info "To reinstall, remove clyde first: rm $INSTALL_DIR/clyde"
        fi
        return 0
    fi

    log_info "Installing Clyde..."

    # Download
    local url
    url=$(get_asset_url "$version" "$os" "$arch")
    local temp_file
    temp_file=$(mktemp)

    log_info "Downloading Clyde v${version}..."
    if ! curl -fL -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/octet-stream" "$url" -o "$temp_file"; then
        rm -f "$temp_file"
        if [[ "$version" != "latest" ]]; then
            log_error "Failed to download Clyde v$version. Please verify the version exists at https://github.com/${GITHUB_REPO}/releases"
        else
            log_error "Failed to download Clyde. Please check your GITHUB_TOKEN and internet connection."
        fi
    fi

    # Extract
    log_info "Extracting..."
    local temp_dir
    temp_dir=$(mktemp -d)

    if ! tar xzf "$temp_file" -C "$temp_dir" 2>/dev/null; then
        rm -f "$temp_file"
        rm -rf "$temp_dir"
        log_error "Failed to extract Clyde binary. The download may be corrupted."
    fi

    # Find and copy binary
    local binary_path="$temp_dir/clyde"
    if [[ ! -f "$binary_path" ]]; then
        rm -f "$temp_file"
        rm -rf "$temp_dir"
        log_error "Clyde binary not found in archive"
    fi

    # Make executable and move to bin
    chmod +x "$binary_path"
    mv "$binary_path" "$INSTALL_DIR/clyde"

    # Cleanup
    rm -f "$temp_file"
    rm -rf "$temp_dir"

    # Verify
    if command_exists clyde; then
        local installed_version
        installed_version=$(clyde version --quiet 2>/dev/null || echo "unknown")
        log_success "Clyde installed successfully: v$installed_version"
    else
        log_error "Installation completed but 'clyde' command not found. You may need to restart your shell."
    fi
}

# Install dependencies using clyde
install_dependencies_via_clyde() {
    if [[ "${INSTALL_DEPENDENCIES:-false}" == "true" ]]; then
        echo ""
        log_info "Installing dependencies via clyde..."
        if clyde install all; then
            log_success "Dependencies installed successfully"
        else
            log_warning "Failed to install some dependencies. You can try again with: clyde install all"
        fi
    fi
}

# Main execution
main() {
    echo ""
    log_info "Clyde Installer"
    echo ""

    # Check for GITHUB_TOKEN
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_error "GITHUB_TOKEN environment variable is required. Create a token at https://github.com/settings/tokens with 'repo' scope and set: export GITHUB_TOKEN=your_token"
    fi

    # Detect system
    local os
    local arch
    local version
    os=$(detect_os)
    arch=$(detect_arch)
    version=$(resolve_version)

    log_info "Detected OS: $os ($arch)"
    if [[ "$version" != "latest" ]]; then
        log_info "Target version: v$version"
    else
        log_info "Target version: latest"
    fi
    echo ""

    # Setup local bin directory
    setup_local_bin
    echo ""

    # Install Clyde
    install_clyde "$os" "$arch" "$version"

    # Optionally install dependencies
    install_dependencies_via_clyde

    # Final summary
    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Quick start:"
    echo "  clyde version        - Show version information"
    echo "  clyde install all    - Install Claude Code, GitHub CLI, and Atlassian CLI"
    echo ""
    echo "Note: If 'clyde' command is not found, restart your shell or run:"
    echo "  source ~/.bashrc    (for bash)"
    echo "  source ~/.zshrc     (for zsh)"
    echo ""
}

# Run main function
main "$@"
