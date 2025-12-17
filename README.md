# DX Installers

Installation scripts for OutSystems DX tools.

## Prerequisites

Create a GitHub personal access token with `repo` scope at https://github.com/settings/tokens

Set the token:
```bash
# macOS / Linux
export GITHUB_TOKEN=your_token_here

# Windows
$env:GITHUB_TOKEN = "your_token_here"
```

## Install Clyde

**macOS / Linux:**
```bash
GITHUB_TOKEN=your_token curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash
```

**Windows:**
```powershell
$env:GITHUB_TOKEN = "your_token"
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1').Content
```

**Or download directly from releases:** https://github.com/OutSystems/dx-claude-code-marketplace/releases

### Options

**Specific version:**
```bash
# macOS / Linux
GITHUB_TOKEN=your_token CLYDE_VERSION=1.0.2 curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash

# Windows
$env:GITHUB_TOKEN = "your_token"
$env:CLYDE_VERSION = "1.0.2"
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1').Content
```

**Install with dependencies (Claude Code CLI, GitHub CLI, Atlassian CLI):**
```bash
# macOS / Linux
GITHUB_TOKEN=your_token INSTALL_DEPENDENCIES=true curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash

# Windows
$env:GITHUB_TOKEN = "your_token"
$env:INSTALL_DEPENDENCIES = "true"
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1').Content
```

## Install Dependencies Only

If you only need Claude Code CLI, GitHub CLI, and Atlassian CLI:

**macOS / Linux:**
```bash
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-dependencies.sh | bash
```

**Windows:**
```powershell
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-dependencies.ps1').Content
```

## Troubleshooting

**Command not found after installation:** Restart your terminal or run `source ~/.bashrc` (bash) / `source ~/.zshrc` (zsh).

**Installs to:** `~/.local/bin` (Unix) or `%USERPROFILE%\.local\bin` (Windows).

## License

CC0-1.0 License. See [LICENSE](LICENSE) for details.
