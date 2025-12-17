# DX Installers

Installation scripts for OutSystems DX tools.

## Install Clyde

**macOS / Linux:**
```bash
curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash
```

**Windows:**
```powershell
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1').Content
```

### Options

**Specific version:**
```bash
# macOS / Linux
CLYDE_VERSION=1.0.2 curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash

# Windows
$env:CLYDE_VERSION = "1.0.2"
iex (iwr 'https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.ps1').Content
```

**Install with dependencies (Claude Code CLI, GitHub CLI, Atlassian CLI):**
```bash
# macOS / Linux
INSTALL_DEPENDENCIES=true curl -sfL https://raw.githubusercontent.com/renato0307/dx-installers/main/install-clyde.sh | bash

# Windows
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
