#!/usr/bin/env pwsh
# Installation script for Claude Code CLI, GitHub CLI, and Atlassian CLI
# Supports Windows without requiring package managers
#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Logging functions
function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

function Write-LogWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Check if command exists
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Detect architecture
function Get-Architecture {
    if ([Environment]::Is64BitOperatingSystem) {
        $arch = $env:PROCESSOR_ARCHITECTURE
        if ($arch -eq "ARM64") {
            return "arm64"
        }
        return "amd64"
    }
    return "386"
}

# Check if running as admin (informational only)
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Setup user's local bin directory and add to PATH
function Initialize-LocalBin {
    $binDir = Join-Path $env:USERPROFILE ".local\bin"

    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
        Write-LogInfo "Created $binDir"
    }

    # Add to PATH if not already present
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$binDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
        $env:Path += ";$binDir"
        Write-LogInfo "Added $binDir to user PATH"
    }

    return $binDir
}

# Install Claude Code CLI
function Install-ClaudeCode {
    Write-LogInfo "Checking Claude Code CLI..."

    if (Test-CommandExists claude) {
        try {
            $version = & claude --version 2>$null
            Write-LogSuccess "Claude Code CLI already installed: $version"
            return
        } catch {
            Write-LogSuccess "Claude Code CLI already installed"
            return
        }
    }

    Write-LogInfo "Installing Claude Code CLI..."

    try {
        # Use Claude's official PowerShell installer
        $installScript = Invoke-RestMethod https://claude.ai/install.ps1
        Invoke-Expression $installScript

        if (Test-CommandExists claude) {
            try {
                $version = & claude --version 2>$null
                Write-LogSuccess "Claude Code CLI installed successfully: $version"
            } catch {
                Write-LogSuccess "Claude Code CLI installed successfully"
            }
        } else {
            Write-LogError "Claude Code CLI installation completed but 'claude' command not found. You may need to restart your shell."
        }
    } catch {
        Write-LogError "Failed to install Claude Code CLI: $_"
    }
}

# Install GitHub CLI
function Install-GitHubCLI {
    param([string]$BinDir, [string]$Arch)

    Write-LogInfo "Checking GitHub CLI..."

    if (Test-CommandExists gh) {
        try {
            $version = (& gh --version)[0]
            Write-LogSuccess "GitHub CLI already installed: $version"
            return
        } catch {
            Write-LogSuccess "GitHub CLI already installed"
            return
        }
    }

    Write-LogInfo "Installing GitHub CLI..."

    try {
        # Get latest version from GitHub API
        Write-LogInfo "Fetching latest GitHub CLI version..."
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/cli/cli/releases/latest"
        $version = $release.tag_name.TrimStart('v')

        Write-LogInfo "Latest version: v$version"

        # Find Windows zip asset
        $assetName = "gh_${version}_windows_${Arch}.zip"
        $asset = $release.assets | Where-Object { $_.name -eq $assetName }

        if ($null -eq $asset) {
            Write-LogError "Could not find GitHub CLI release for architecture: $Arch"
        }

        $url = $asset.browser_download_url

        # Download
        Write-LogInfo "Downloading from $url..."
        $tempFile = Join-Path $env:TEMP "gh.zip"
        Invoke-WebRequest -Uri $url -OutFile $tempFile

        # Extract
        $extractPath = Join-Path $env:TEMP "gh_extract"
        if (Test-Path $extractPath) {
            Remove-Item -Path $extractPath -Recurse -Force
        }
        Expand-Archive -Path $tempFile -DestinationPath $extractPath -Force

        # Find and copy gh.exe
        $ghExePath = Get-ChildItem -Path $extractPath -Filter "gh.exe" -Recurse | Select-Object -First 1

        if ($null -eq $ghExePath) {
            Write-LogError "Could not find gh.exe in downloaded archive"
        }

        Copy-Item -Path $ghExePath.FullName -Destination (Join-Path $BinDir "gh.exe") -Force

        # Cleanup
        Remove-Item -Path $tempFile -Force
        Remove-Item -Path $extractPath -Recurse -Force

        # Verify installation
        $env:Path += ";$BinDir"
        if (Test-CommandExists gh) {
            try {
                $installedVersion = (& gh --version)[0]
                Write-LogSuccess "GitHub CLI installed successfully: $installedVersion"
            } catch {
                Write-LogSuccess "GitHub CLI installed successfully"
            }
        } else {
            Write-LogError "GitHub CLI binary copied but 'gh' command not found. Please restart your shell."
        }
    } catch {
        Write-LogError "Failed to install GitHub CLI: $_"
    }
}

# Install Atlassian CLI
function Install-AtlassianCLI {
    param([string]$BinDir, [string]$Arch)

    Write-LogInfo "Checking Atlassian CLI..."

    if (Test-CommandExists acli) {
        try {
            $version = & acli --version 2>$null
            Write-LogSuccess "Atlassian CLI already installed: $version"
            return
        } catch {
            Write-LogSuccess "Atlassian CLI already installed"
            return
        }
    }

    Write-LogInfo "Installing Atlassian CLI..."

    try {
        # Determine download URL based on architecture
        $url = "https://acli.atlassian.com/windows/latest/acli_windows_${Arch}/acli.exe"

        # Download binary
        Write-LogInfo "Downloading from $url..."
        $acliPath = Join-Path $BinDir "acli.exe"
        Invoke-WebRequest -Uri $url -OutFile $acliPath

        # Verify installation
        $env:Path += ";$BinDir"
        if (Test-CommandExists acli) {
            try {
                $version = & acli --version 2>$null
                Write-LogSuccess "Atlassian CLI installed successfully: $version"
            } catch {
                Write-LogSuccess "Atlassian CLI installed successfully"
            }
        } else {
            Write-LogError "Atlassian CLI binary downloaded but 'acli' command not found. Please restart your shell."
        }
    } catch {
        Write-LogError "Failed to install Atlassian CLI: $_"
    }
}

# Main execution
function Main {
    Write-Host ""
    Write-LogInfo "Starting dependency installation..."
    Write-Host ""

    # Detect architecture
    $arch = Get-Architecture
    Write-LogInfo "Detected architecture: $arch"

    # Check admin status (informational)
    if (-not (Test-IsAdmin)) {
        Write-LogInfo "Running without administrator privileges (this is fine)"
    }
    Write-Host ""

    # Setup local bin directory
    $binDir = Initialize-LocalBin
    Write-Host ""

    # Install dependencies
    Install-ClaudeCode
    Write-Host ""

    Install-GitHubCLI -BinDir $binDir -Arch $arch
    Write-Host ""

    Install-AtlassianCLI -BinDir $binDir -Arch $arch
    Write-Host ""

    # Final summary
    Write-LogSuccess "All dependencies installed successfully!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Restart your PowerShell session to refresh PATH"
    Write-Host "2. Start Claude Code and run: /login"
    Write-Host "3. Authenticate GitHub CLI: gh auth login"
    Write-Host "4. Authenticate Atlassian CLI: acli jira auth login"
    Write-Host ""
}

# Run main function
Main
