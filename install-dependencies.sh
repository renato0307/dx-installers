#!/usr/bin/env bash
# Installation script for Claude Code CLI, GitHub CLI, and Atlassian CLI
# Supports macOS and Linux without requiring package managers
set -euo pipefail

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
            echo "macos"
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
    local bin_dir="$HOME/.local/bin"

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

# Install Claude Code CLI
install_claude_code() {
    log_info "Checking Claude Code CLI..."

    if command_exists claude; then
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")
        log_success "Claude Code CLI already installed: $version"
        return 0
    fi

    log_info "Installing Claude Code CLI..."

    # Use Claude's official installer
    if curl -fsSL https://claude.ai/install.sh | bash; then
        if command_exists claude; then
            local version
            version=$(claude --version 2>/dev/null || echo "unknown")
            log_success "Claude Code CLI installed successfully: $version"
        else
            log_error "Claude Code CLI installation completed but 'claude' command not found. You may need to restart your shell."
        fi
    else
        log_error "Failed to install Claude Code CLI"
    fi
}

# Install GitHub CLI
install_github_cli() {
    log_info "Checking GitHub CLI..."

    if command_exists gh; then
        local version
        version=$(gh --version 2>/dev/null | head -1 || echo "unknown")
        log_success "GitHub CLI already installed: $version"
        return 0
    fi

    log_info "Installing GitHub CLI..."

    local os="$1"
    local arch="$2"
    local temp_dir
    temp_dir=$(mktemp -d)

    # Get latest version from GitHub API
    log_info "Fetching latest GitHub CLI version..."
    local version
    version=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')

    if [[ -z "$version" ]]; then
        rm -rf "$temp_dir"
        log_error "Failed to fetch GitHub CLI version"
    fi

    log_info "Latest version: v$version"

    # Determine download URL based on OS and arch
    local url
    local filename
    if [[ "$os" == "macos" ]]; then
        if [[ "$arch" == "arm64" ]]; then
            filename="gh_${version}_macOS_arm64.tar.gz"
        else
            filename="gh_${version}_macOS_amd64.tar.gz"
        fi
    else
        filename="gh_${version}_linux_amd64.tar.gz"
    fi

    url="https://github.com/cli/cli/releases/download/v${version}/${filename}"

    # Download and extract
    log_info "Downloading from $url..."
    if curl -L "$url" | tar xz -C "$temp_dir"; then
        # Find the extracted directory (it includes version in name)
        local extract_dir
        extract_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "gh_*" | head -1)

        if [[ -z "$extract_dir" ]]; then
            rm -rf "$temp_dir"
            log_error "Failed to find extracted GitHub CLI directory"
        fi

        # Copy binary to ~/.local/bin
        cp "$extract_dir/bin/gh" "$HOME/.local/bin/gh"
        chmod +x "$HOME/.local/bin/gh"

        # Cleanup
        rm -rf "$temp_dir"

        if command_exists gh; then
            local installed_version
            installed_version=$(gh --version 2>/dev/null | head -1 || echo "unknown")
            log_success "GitHub CLI installed successfully: $installed_version"
        else
            log_error "GitHub CLI binary copied but 'gh' command not found. Please check your PATH."
        fi
    else
        rm -rf "$temp_dir"
        log_error "Failed to download or extract GitHub CLI"
    fi
}

# Install Atlassian CLI
install_atlassian_cli() {
    log_info "Checking Atlassian CLI..."

    if command_exists acli; then
        local version
        version=$(acli --version 2>/dev/null || echo "unknown")
        log_success "Atlassian CLI already installed: $version"
        return 0
    fi

    log_info "Installing Atlassian CLI..."

    local os="$1"
    local arch="$2"
    local temp_file
    temp_file=$(mktemp)

    # Determine download URL based on OS and arch
    local url
    if [[ "$os" == "macos" ]]; then
        if [[ "$arch" == "arm64" ]]; then
            url="https://acli.atlassian.com/darwin/latest/acli_darwin_arm64/acli"
        else
            url="https://acli.atlassian.com/darwin/latest/acli_darwin_amd64/acli"
        fi
    else
        url="https://acli.atlassian.com/linux/latest/acli_linux_amd64/acli"
    fi

    # Download binary
    log_info "Downloading from $url..."
    if curl -L "$url" -o "$temp_file"; then
        # Make executable and move to bin
        chmod +x "$temp_file"
        mv "$temp_file" "$HOME/.local/bin/acli"

        if command_exists acli; then
            local version
            version=$(acli --version 2>/dev/null || echo "unknown")
            log_success "Atlassian CLI installed successfully: $version"
        else
            log_error "Atlassian CLI binary copied but 'acli' command not found. Please check your PATH."
        fi
    else
        rm -f "$temp_file"
        log_error "Failed to download Atlassian CLI"
    fi
}

# Main execution
main() {
    echo ""
    log_info "Starting dependency installation..."
    echo ""

    # Detect system
    local os
    local arch
    os=$(detect_os)
    arch=$(detect_arch)
    log_info "Detected OS: $os ($arch)"
    echo ""

    # Setup local bin directory
    setup_local_bin
    echo ""

    # Install dependencies
    install_claude_code
    echo ""

    install_github_cli "$os" "$arch"
    echo ""

    install_atlassian_cli "$os" "$arch"
    echo ""

    # Final summary
    log_success "All dependencies installed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Start Claude Code and run: /login"
    echo "3. Authenticate GitHub CLI: gh auth login"
    echo "4. Authenticate Atlassian CLI: acli jira auth login"
    echo ""
}

# Run main function
main "$@"
