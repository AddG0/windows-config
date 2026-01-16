# Windows Dotfiles

Declarative Windows configuration, mirroring the NixOS setup pattern.

## Quick Start

On a fresh Windows 11 install, run in PowerShell (Admin):

```powershell
irm https://raw.githubusercontent.com/AddG0/windows-config/main/bootstrap.ps1 | iex
```

This will configure the `demon-windows` host for user `addg` by default.

## Structure

```
.
├── bootstrap.ps1              # Entry point script
├── hosts/                     # System-level configs
│   ├── common/
│   │   ├── core/              # Applied to all hosts
│   │   │   ├── winutil.json   # WinUtil debloat settings
│   │   │   └── apps.winget    # Core apps (Git, 1Password, etc.)
│   │   └── optional/          # Optional system features
│   └── windows/
│       └── demon-windows/     # Host-specific system config
│           └── apps.winget
├── home/                      # User-level configs (Chezmoi)
│   ├── .chezmoi.toml.tmpl     # Chezmoi config template
│   ├── .chezmoiignore         # Conditional ignores
│   ├── common/
│   │   ├── core/              # Applied to all users
│   │   │   ├── cli/           # Shell, prompt configs
│   │   │   ├── terminal/      # Windows Terminal
│   │   │   └── git/           # Git config
│   │   └── optional/          # Feature modules
│   │       ├── ricing/        # GlazeWM, Zebar, etc.
│   │       ├── development/   # Dev tools
│   │       └── gaming/        # Gaming configs
│   └── primary/
│       └── demon-windows/     # User's host-specific config
└── lib/                       # Helper scripts
```

## Components

| Component | Tool | Purpose |
|-----------|------|---------|
| Debloat | WinUtil | Remove bloatware, telemetry |
| Apps | WinGet DSC | Declarative app installation |
| Dotfiles | Chezmoi | Symlink management, templates |
| Secrets | 1Password CLI | Integrated with Chezmoi |

## Adding a New Host

1. Create `hosts/windows/<hostname>/` directory
2. Add `apps.winget` for host-specific apps
3. Optionally add `winutil.json` for custom debloat
4. Create `home/primary/<hostname>/` for user dotfiles
5. Set Windows hostname to match:
   ```powershell
   Rename-Computer -NewName "<hostname>" -Restart
   ```

## Feature Flags

Edit `.chezmoi.toml.tmpl` to enable/disable features:

```toml
[data.features]
    ricing = true      # GlazeWM, Zebar, visual customization
    development = false # Dev tools, editors
    gaming = true      # Gaming optimizations
```

## Manual Operations

Some things can't be automated:

- [ ] Install cursor theme (Settings → Personalization → Themes)
- [ ] Sign into 1Password and enable SSH agent
- [ ] Configure NVIDIA settings
- [ ] Set GlazeWM/Zebar to run at startup

## Keybindings (GlazeWM)

| Key | Action |
|-----|--------|
| `Alt + Enter` | Open terminal |
| `Alt + Q` | Close window |
| `Alt + H/J/K/L` | Focus left/down/up/right |
| `Alt + Shift + H/J/K/L` | Move window |
| `Alt + 1-9` | Switch workspace |
| `Alt + Shift + 1-9` | Move to workspace |
| `Alt + Space` | Toggle floating |
| `Alt + F` | Toggle fullscreen |
| `Alt + Shift + R` | Reload config |

## Comparison with NixOS Setup

| NixOS | Windows Equivalent |
|-------|-------------------|
| `flake.nix` | `bootstrap.ps1` |
| `hosts/<host>/` | `hosts/windows/<host>/` |
| `home/<user>/<host>.nix` | `home/primary/<host>/` |
| `home/common/core/` | `home/common/core/` |
| `home/common/optional/` | `home/common/optional/` |
| Home Manager | Chezmoi |
| Nix packages | WinGet DSC |
