# Windows Declarative Configuration

Declarative Windows configuration using [WinGet DSC](https://learn.microsoft.com/en-us/windows/package-manager/configuration/) profiles. Inspired by [NixOS](https://nixos.org/) - define your system state, apply it, and get the same result every time.

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
├── configurations/           # DSC profiles (composable units)
│   ├── core.dsc.yaml        # Base system: Git, terminal, security, utilities
│   ├── gaming.dsc.yaml      # Gaming: Steam, Discord, NVIDIA, OBS
│   ├── ricing.dsc.yaml      # Customization: GlazeWM, Zebar, fonts
│   └── development.dsc.yaml # Dev tools: VS Code, languages, extensions
│
├── hosts/                   # Per-machine configurations
│   └── demon.yaml           # Host config - declares which profiles to apply
│
├── home/                    # Dotfiles (managed by Chezmoi)
│   ├── .chezmoi.toml.tmpl   # Chezmoi config with feature flags
│   └── common/              # Shared dotfiles
│       ├── core/            # Always applied (terminal, git, shell)
│       └── optional/        # Feature-gated (ricing configs, etc.)
│
├── lib/                     # Supporting files
│   └── winutil.json         # WinUtil debloat configuration
│
├── Apply-Config.ps1         # Main entry point - applies configuration
└── bootstrap.ps1            # One-liner bootstrap for fresh installs
```

## Profiles

Profiles are DSC configuration files that declare packages and settings. They're composable - pick what you need:

| Profile | Description | Packages |
|---------|-------------|----------|
| **core** | Base system (always apply first) | Git, Chezmoi, Terminal, Oh-My-Posh, 1Password, PowerToys, 7-Zip |
| **gaming** | Gaming setup | Steam, Discord, Valorant, NVIDIA GeForce, OBS |
| **ricing** | Window manager & theming | GlazeWM, Zebar, TranslucentTB, MicaForEveryone, Nerd Fonts |
| **development** | Development tools | VS Code, Claude Code, Chrome, Git config, VS Code extensions |

## Host Configuration

Each machine has a YAML file in `hosts/` that declares its desired state:

```yaml
# hosts/demon.yaml
hostname: demon
description: Primary gaming and development workstation

profiles:
  - core        # Base system - always first
  - gaming      # Steam, Discord, NVIDIA
  - ricing      # GlazeWM, Zebar, theming
  - development # VS Code, dev tools

debloat:
  enabled: true
  config: lib/winutil.json

dotfiles:
  enabled: true
  features:
    ricing: true
    development: true
```

## Usage

### Apply Configuration

```powershell
# Apply full configuration for this host
.\Apply-Config.ps1

# Apply specific profiles only
.\Apply-Config.ps1 -Profiles core,development

# Skip debloat or dotfiles
.\Apply-Config.ps1 -SkipDebloat
.\Apply-Config.ps1 -SkipDotfiles
```

### Add a New Host

1. Create `hosts/my-laptop.yaml` with your profile selection
2. Run `.\Apply-Config.ps1 -HostName my-laptop`

### Add a New Profile

1. Create `configurations/myprofile.dsc.yaml`
2. Add packages and settings using [DSC resources](https://learn.microsoft.com/en-us/windows/package-manager/configuration/)
3. Add to your host's `profiles` list

## How It Works

1. **Bootstrap** clones this repo and runs `Apply-Config.ps1`
2. **Apply-Config** reads your host's YAML and applies:
   - WinUtil debloat (optional) - removes bloatware, disables telemetry
   - DSC profiles - installs packages, configures settings
   - Chezmoi dotfiles - deploys user configurations
3. **State snapshots** are saved before changes for potential rollback

## DSC Resources Used

- `Microsoft.WinGet.DSC/WinGetPackage` - Install packages via WinGet
- `Microsoft.Windows.Developer/*` - Developer mode, dark mode, Explorer settings
- `GitDsc/*` - Git configuration
- `Microsoft.VSCode.Dsc/*` - VS Code extensions

See [Microsoft's DSC resources](https://github.com/microsoft/winget-dsc) for full documentation.

## Dotfiles (Chezmoi)

User configurations are managed by [Chezmoi](https://chezmoi.io/) in the `home/` directory:

- **Feature flags** in `.chezmoi.toml.tmpl` control which configs are applied
- **Templates** allow per-machine customization (email, hostname, etc.)
- Run `chezmoi diff` to see pending changes
- Run `chezmoi apply` to apply dotfiles only

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

## Manual Operations

Some things can't be automated:

- [ ] Sign into 1Password and enable SSH agent
- [ ] Configure NVIDIA settings
- [ ] Set GlazeWM to run at startup

## Credits

- [WinGet Configuration](https://learn.microsoft.com/en-us/windows/package-manager/configuration/) - Microsoft's declarative package management
- [ChrisTitusTech WinUtil](https://github.com/ChrisTitusTech/winutil) - Windows debloating
- [Chezmoi](https://chezmoi.io/) - Dotfile management
- [atc-net/atc-winget-configurations](https://github.com/atc-net/atc-winget-configurations) - Profile organization inspiration
