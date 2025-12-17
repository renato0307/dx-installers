# DX Installers

Installation scripts for OutSystems DX tools.

## Quick Start

### Install Clyde (Bash/Linux/macOS)

**Latest version:**
```bash
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash
```

**Specific version:**
```bash
export CLYDE_VERSION=1.0.2
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash
```

**With dependencies:**
```bash
export INSTALL_DEPENDENCIES=true
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash
```

### Install Clyde (PowerShell/Windows)

**Latest version:**
```powershell
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1').Content
```

**Specific version:**
```powershell
$env:CLYDE_VERSION = "1.0.2"
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1').Content
```

**With dependencies:**
```powershell
$env:INSTALL_DEPENDENCIES = "true"
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1').Content
```

## Available Scripts

### install-clyde.sh / install-clyde.ps1

Installs the Clyde CLI tool to `~/.local/bin` (Unix) or `%USERPROFILE%\.local\bin` (Windows).

**What is Clyde?**

Clyde is the OutSystems DX CLI tool for Claude Code workflows. It helps you manage and install development tools needed for Claude Code integration.

**Environment Variables:**

- `CLYDE_VERSION` - Install specific version (e.g., "1.0.2"). Default: latest
- `INSTALL_DEPENDENCIES` - If "true", also installs Claude Code CLI, GitHub CLI, and Atlassian CLI via `clyde install all`. Default: false

**Supported Platforms:**

- macOS: darwin/amd64, darwin/arm64
- Linux: linux/amd64, linux/arm64
- Windows: windows/amd64, windows/arm64

**Features:**

- Idempotent (safe to run multiple times)
- Automatic PATH configuration
- Version selection support
- Optional dependency installation

**Usage Examples:**

```bash
# Install latest version
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash

# Install specific version
export CLYDE_VERSION=1.0.2
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash

# Install with all dependencies
export INSTALL_DEPENDENCIES=true
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash
```

### install-dependencies.sh / install-dependencies.ps1

Installs Claude Code CLI, GitHub CLI, and Atlassian CLI to `~/.local/bin` (Unix) or `%USERPROFILE%\.local\bin` (Windows).

**What it installs:**

- **Claude Code CLI** - Official Claude Code command-line interface
- **GitHub CLI (gh)** - GitHub's official command-line tool
- **Atlassian CLI (acli)** - Atlassian's command-line interface for Jira and Confluence

**Usage:**

**Bash (macOS/Linux):**
```bash
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-dependencies.sh | bash
```

**PowerShell (Windows):**
```powershell
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-dependencies.ps1').Content
```

**Note:** You can also install these dependencies using Clyde:
```bash
clyde install all
```

## Installation Location

All tools are installed to:

- **Unix** (macOS/Linux): `~/.local/bin`
- **Windows**: `%USERPROFILE%\.local\bin`

This location is automatically added to your PATH by the installer scripts.

## Troubleshooting

### Command not found after installation

1. **Restart your shell/terminal** - This is the most common solution
2. **Manually reload your shell configuration:**
   - Bash: `source ~/.bashrc`
   - Zsh: `source ~/.zshrc`
   - PowerShell: Restart the PowerShell session
3. **Verify PATH** - Check that the bin directory is in your PATH:
   - Unix: `echo $PATH | grep .local/bin`
   - Windows: `$env:Path -split ';' | Select-String '.local'`

### Permission denied

- **Unix**: Ensure you have write access to `~/.local/bin`. The script does not require sudo.
- **Windows**: The scripts use user-level PATH (no administrator privileges required). If you encounter issues, try running PowerShell as administrator.

### Download fails

- **Check internet connection** - Ensure you can access GitHub
- **Verify repository access** - The OutSystems dx-claude-code-marketplace repository may require authentication
- **Try specific version** - If "latest" fails, try a specific version number
- **Check firewall/proxy** - Corporate networks may block GitHub downloads

### Version not found

- **Verify version exists** - Check available releases at https://github.com/OutSystems/dx-claude-code-marketplace/releases
- **Use correct format** - Version should be like "1.0.2" (not "v1.0.2")
- **Check tag prefix** - Clyde releases use the tag format `clyde-v{VERSION}`

### Installation succeeds but command not found

This usually means the PATH wasn't updated in your current shell session:

1. **Open a new terminal/shell window** - The PATH should be set correctly
2. **Check installation** - Verify the binary exists:
   - Unix: `ls -la ~/.local/bin/clyde`
   - Windows: `Get-Item $env:USERPROFILE\.local\bin\clyde.exe`
3. **Manually add to PATH** (temporary):
   - Unix: `export PATH="$HOME/.local/bin:$PATH"`
   - Windows: `$env:Path += ";$env:USERPROFILE\.local\bin"`

## Development

### Testing Scripts Locally

**Clone the repository:**
```bash
git clone https://github.com/renato0307/dx-installers.git
cd dx-installers
```

**Test Bash script:**
```bash
bash install-clyde.sh
```

**Test PowerShell script:**
```powershell
.\install-clyde.ps1
```

### Environment Variables for Testing

**Unix:**
```bash
# Test specific version
export CLYDE_VERSION=1.0.2
bash install-clyde.sh

# Test with dependencies
export INSTALL_DEPENDENCIES=true
bash install-clyde.sh

# Test both
export CLYDE_VERSION=1.0.2
export INSTALL_DEPENDENCIES=true
bash install-clyde.sh
```

**Windows:**
```powershell
# Test specific version
$env:CLYDE_VERSION = "1.0.2"
.\install-clyde.ps1

# Test with dependencies
$env:INSTALL_DEPENDENCIES = "true"
.\install-clyde.ps1
```

## Script Features

### Idempotency

All scripts are idempotent - you can run them multiple times safely:

- If a tool is already installed, the script skips it and reports the current version
- If a specific version is requested but a different version is installed, the script warns you
- No duplicate PATH entries are created

### Error Handling

Scripts include comprehensive error handling:

- Clear, color-coded log messages (INFO, SUCCESS, WARNING, ERROR)
- Automatic cleanup of temporary files on error
- Non-zero exit codes on failure for CI/CD integration
- Helpful error messages with troubleshooting hints

### Platform Detection

Scripts automatically detect:

- Operating system (macOS, Linux, Windows)
- Architecture (amd64, arm64, 386)
- Shell type (bash, zsh)
- Appropriate archive format (.tar.gz for Unix, .zip for Windows)

## Security Considerations

### Download Security

- All downloads use HTTPS
- Downloads from official GitHub releases
- Future enhancement: Checksum verification

### Execution Security

When using `curl | bash` or `iex (iwr ...)` patterns:

- Review the script before running: https://github.com/renato0307/dx-installers
- Scripts are open source and can be audited
- No arbitrary code execution from untrusted sources
- Consider downloading and inspecting locally first

**Download and inspect before running:**

```bash
# Unix
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh -o install-clyde.sh
cat install-clyde.sh  # Review the script
bash install-clyde.sh

# Windows
Invoke-WebRequest 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1' -OutFile install-clyde.ps1
Get-Content install-clyde.ps1  # Review the script
.\install-clyde.ps1
```

## Support

For issues, questions, or contributions, please visit:

- **Clyde**: https://github.com/OutSystems/dx-claude-code-marketplace
- **Installers**: https://github.com/renato0307/dx-installers

## License

CC0-1.0 License. See [LICENSE](LICENSE) for details.
