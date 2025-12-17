#!/usr/bin/env pwsh
# Installation script for Clyde CLI
# Supports Windows
#
# Environment variables:
#   $env:CLYDE_VERSION - Install specific version (e.g., "1.0.2"). Default: latest
#   $env:INSTALL_DEPENDENCIES - If "true", runs "clyde install all" after installation
#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Configuration
$GITHUB_REPO = "OutSystems/dx-claude-code-marketplace"
$INSTALL_DIR = Join-Path $env:USERPROFILE ".local\bin"

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

# Setup user's local bin directory and add to PATH
function Initialize-LocalBin {
    $binDir = $INSTALL_DIR

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

# Resolve version to install
function Resolve-Version {
    if ($env:CLYDE_VERSION) {
        return $env:CLYDE_VERSION
    }
    return "latest"
}

# Construct download URL
function Get-DownloadUrl {
    param([string]$Version, [string]$Arch)

    if ($Version -eq "latest") {
        return "https://github.com/$GITHUB_REPO/releases/latest/download/clyde_windows_${Arch}.zip"
    } else {
        return "https://github.com/$GITHUB_REPO/releases/download/clyde-v${Version}/clyde_windows_${Arch}.zip"
    }
}

# Install Clyde binary
function Install-Clyde {
    param([string]$BinDir, [string]$Arch, [string]$Version)

    # Check if already installed
    if (Test-CommandExists clyde) {
        try {
            $currentVersion = & clyde version --quiet 2>$null
            Write-LogSuccess "Clyde already installed: v$currentVersion"

            if (($Version -ne "latest") -and ($currentVersion -ne $Version)) {
                Write-LogWarning "Installed version (v$currentVersion) differs from requested version (v$Version)"
                Write-LogInfo "To reinstall, remove clyde first: Remove-Item '$BinDir\clyde.exe'"
            }
            return
        } catch {
            Write-LogSuccess "Clyde already installed"
            return
        }
    }

    Write-LogInfo "Installing Clyde..."

    try {
        # Download
        $url = Get-DownloadUrl -Version $Version -Arch $Arch
        $tempFile = Join-Path $env:TEMP "clyde.zip"

        Write-LogInfo "Downloading from $url..."
        try {
            Invoke-WebRequest -Uri $url -OutFile $tempFile -ErrorAction Stop
        } catch {
            if ($Version -ne "latest") {
                Write-LogError "Failed to download Clyde v$Version. Please verify the version exists at https://github.com/$GITHUB_REPO/releases"
            } else {
                Write-LogError "Failed to download Clyde. Please check your internet connection."
            }
        }

        # Extract
        Write-LogInfo "Extracting..."
        $extractPath = Join-Path $env:TEMP "clyde_extract"
        if (Test-Path $extractPath) {
            Remove-Item -Path $extractPath -Recurse -Force
        }
        Expand-Archive -Path $tempFile -DestinationPath $extractPath -Force

        # Find and copy clyde.exe
        $clydeExePath = Get-ChildItem -Path $extractPath -Filter "clyde.exe" -Recurse | Select-Object -First 1

        if ($null -eq $clydeExePath) {
            Write-LogError "Clyde.exe not found in archive"
        }

        Copy-Item -Path $clydeExePath.FullName -Destination (Join-Path $BinDir "clyde.exe") -Force

        # Cleanup
        Remove-Item -Path $tempFile -Force
        Remove-Item -Path $extractPath -Recurse -Force

        # Verify installation
        $env:Path += ";$BinDir"
        if (Test-CommandExists clyde) {
            try {
                $installedVersion = & clyde version --quiet 2>$null
                Write-LogSuccess "Clyde installed successfully: v$installedVersion"
            } catch {
                Write-LogSuccess "Clyde installed successfully"
            }
        } else {
            Write-LogError "Installation completed but 'clyde' command not found. You may need to restart your shell."
        }
    } catch {
        Write-LogError "Failed to install Clyde: $_"
    }
}

# Install dependencies using clyde
function Install-DependenciesViaClyde {
    if ($env:INSTALL_DEPENDENCIES -eq "true") {
        Write-Host ""
        Write-LogInfo "Installing dependencies via clyde..."
        try {
            & clyde install all
            Write-LogSuccess "Dependencies installed successfully"
        } catch {
            Write-LogWarning "Failed to install some dependencies. You can try again with: clyde install all"
        }
    }
}

# Main execution
function Main {
    Write-Host ""
    Write-LogInfo "Clyde Installer"
    Write-Host ""

    # Detect architecture
    $arch = Get-Architecture
    $version = Resolve-Version

    Write-LogInfo "Detected architecture: $arch"
    if ($version -ne "latest") {
        Write-LogInfo "Target version: v$version"
    } else {
        Write-LogInfo "Target version: latest"
    }
    Write-Host ""

    # Setup local bin directory
    $binDir = Initialize-LocalBin
    Write-Host ""

    # Install Clyde
    Install-Clyde -BinDir $binDir -Arch $arch -Version $version

    # Optionally install dependencies
    Install-DependenciesViaClyde

    # Final summary
    Write-Host ""
    Write-LogSuccess "Installation complete!"
    Write-Host ""
    Write-Host "Quick start:"
    Write-Host "  clyde version        - Show version information"
    Write-Host "  clyde install all    - Install Claude Code, GitHub CLI, and Atlassian CLI"
    Write-Host ""
    Write-Host "Note: If 'clyde' command is not found, restart your PowerShell session"
    Write-Host ""
}

# Run main function
Main
