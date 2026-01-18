# Windows Declarative Configuration

Declarative Windows configuration using [DSC v3](https://learn.microsoft.com/en-us/powershell/dsc/overview) and [Chezmoi](https://chezmoi.io/). Inspired by [NixOS](https://nixos.org/) - define your system state, apply it, and get the same result every time.

## Quick Start

Run this in an **Administrator PowerShell**:

```powershell
irm https://raw.githubusercontent.com/AddG0/windows-config/main/bootstrap.ps1 | iex
```

Or skip debloat:

```powershell
$params = @{ SkipDebloat = $true }
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/AddG0/windows-config/main/bootstrap.ps1))) @params
```

## Structure

```
windows-config/
├── hosts/                              # DSC configurations
│   ├── demon.dsc.config.yaml           # Host config (includes profiles)
│   ├── core/                           # Core profile (always applied)
│   │   ├── all.dsc.config.yaml         # Includes all core configs
│   │   ├── packages.dsc.config.yaml    # Core packages (Git, WezTerm, etc.)
│   │   ├── settings.dsc.config.yaml    # Windows settings
│   │   └── system.dsc.config.yaml      # System configuration
│   └── optional/                       # Optional profiles
│       ├── browsers.dsc.config.yaml    # Browsers (Firefox, Chrome)
│       ├── development/                # Dev tools
│       │   ├── all.dsc.config.yaml
│       │   └── packages.dsc.config.yaml
│       ├── gaming/                     # Gaming packages
│       │   └── packages.dsc.config.yaml
│       └── ricing/                     # Ricing packages (GlazeWM, etc.)
│           └── packages.dsc.config.yaml
│
├── home/                               # Dotfiles (Chezmoi)
│   ├── .chezmoi.toml.tmpl              # Chezmoi config
│   ├── .chezmoiignore                  # Conditional ignores
│   ├── dot_gitconfig.tmpl              # → ~/.gitconfig
│   ├── dot_config/
│   │   └── wezterm/wezterm.lua         # → ~/.config/wezterm/
│   ├── dot_glzr/                       # → ~/.glzr/
│   │   ├── glazewm/config.yaml
│   │   └── zebar/config.yaml
│   ├── OneDrive/Documents/PowerShell/
│   │   └── Microsoft.PowerShell_profile.ps1
│   └── AppData/Roaming/Code/User/
│       └── settings.json               # VS Code settings
│
├── lib/
│   └── winutil.json                    # WinUtil debloat config
│
├── Apply-Config.ps1                    # Main entry point
└── bootstrap.ps1                       # One-liner bootstrap
```

## Profiles

| Profile | Description | Key Packages |
|---------|-------------|--------------|
| **core** | Base system (always first) | Git, WezTerm, Oh-My-Posh, 1Password, PowerToys, 7-Zip, Nerd Font |
| **gaming** | Gaming setup | Steam, Discord, Valorant, NVIDIA, OBS |
| **ricing** | Window manager & theming | GlazeWM, Zebar |
| **development** | Dev tools | VS Code, languages, extensions |
| **browsers** | Web browsers | Firefox, Chrome |

## Usage

### Apply Full Configuration

```powershell
.\Apply-Config.ps1
```

### Apply Dotfiles Only (Fast)

```powershell
.\Apply-Config.ps1 -DotfilesOnly
```

### With Debloat

```powershell
.\Apply-Config.ps1 -Debloat
```

### Flags

| Flag | Description |
|------|-------------|
| `-DotfilesOnly` | Only apply Chezmoi dotfiles (skip DSC) |
| `-Debloat` | Run WinUtil debloat |
| `-SkipDotfiles` | Skip Chezmoi dotfiles |
| `-ProfilesOnly` | Only apply DSC profiles |
| `-HostName` | Specify host config to use |

## Dotfiles (Chezmoi)

User configs managed by Chezmoi:

| File | Target |
|------|--------|
| `dot_gitconfig.tmpl` | `~/.gitconfig` |
| `dot_config/wezterm/` | `~/.config/wezterm/` |
| `dot_glzr/` | `~/.glzr/` |
| `OneDrive/Documents/PowerShell/` | PowerShell profile |
| `AppData/Roaming/Code/User/` | VS Code settings |

## WezTerm Keybindings

Leader key: `Ctrl+Space`

| Key | Action |
|-----|--------|
| `Leader + -` | Split vertical |
| `Leader + \` | Split horizontal |
| `Leader + h/j/k/l` | Navigate panes |
| `Leader + H/J/K/L` | Resize panes |
| `Leader + x` | Close pane |
| `Leader + z` | Toggle maximize |
| `Leader + c` | New tab |
| `Leader + n/p` | Next/prev tab |
| `Leader + 1-5` | Go to tab |
| `Leader + m` | Move window |

## Git Aliases (PowerShell)

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gco` | `git checkout` |
| `gst` | `git status` |
| `gd` | `git diff` |
| `gl` | `git pull` |
| `gp` | `git push` |
| `gpf` | `git push --force-with-lease` |
| `glog` | `git log --graph` |
| `grhs` | `git reset --soft` |

## 1Password SSH

SSH authentication via 1Password:

1. Enable SSH Agent in 1Password settings
2. Add SSH key to GitHub/GitLab
3. Test: `ssh -T git@github.com`

## Manual Steps

After bootstrap:

- [ ] Sign into 1Password and enable SSH agent
- [ ] Run `ssh -T git@github.com` to verify SSH
- [ ] Start GlazeWM (if ricing enabled)

## Credits

- [DSC v3](https://learn.microsoft.com/en-us/powershell/dsc/overview) - Microsoft's declarative configuration
- [ChrisTitusTech WinUtil](https://github.com/ChrisTitusTech/winutil) - Windows debloating
- [Chezmoi](https://chezmoi.io/) - Dotfile management
- [WezTerm](https://wezterm.org/) - GPU-accelerated terminal
- [1Password SSH](https://developer.1password.com/docs/ssh/) - SSH key management
