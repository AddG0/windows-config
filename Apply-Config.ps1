<#
.SYNOPSIS
    Applies declarative Windows configuration using DSC v3.

.DESCRIPTION
    Uses Microsoft DSC v3 to apply host configurations with includes,
    WinUtil debloat settings, and Chezmoi dotfiles.

.PARAMETER HostName
    The hostname to configure. Defaults to the current computer name or 'demon'.

.PARAMETER Debloat
    Run WinUtil debloat. Only runs during bootstrap by default.

.PARAMETER SkipDotfiles
    Skip the Chezmoi dotfiles step.

.PARAMETER ProfilesOnly
    Only apply DSC profiles, skip debloat and dotfiles.

.PARAMETER DotfilesOnly
    Only apply Chezmoi dotfiles, skip DSC and debloat. Fast mode.

.EXAMPLE
    .\Apply-Config.ps1
    # Apply full configuration for this host

.EXAMPLE
    .\Apply-Config.ps1 -HostName demon
    # Apply configuration for a specific host

.EXAMPLE
    .\Apply-Config.ps1 -DotfilesOnly
    # Fast mode - only apply Chezmoi dotfiles, skip DSC
#>

param(
    [string]$HostName = "",
    [switch]$Debloat,        # Only run debloat if explicitly requested
    [switch]$SkipDotfiles,
    [switch]$ProfilesOnly,
    [switch]$DotfilesOnly    # Only run chezmoi, skip DSC (fast mode)
)

$ErrorActionPreference = "Stop"
$ConfigRoot = $PSScriptRoot

# ============================================
# Helper Functions
# ============================================

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "`n=== $Message ===" -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Gray
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "  [SKIP] $Message" -ForegroundColor DarkGray
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-HostConfig {
    param([string]$HostName)

    # Read from the unified DSC config file
    $configPath = Join-Path $ConfigRoot "hosts\$HostName.dsc.config.yaml"

    if (-not (Test-Path $configPath)) {
        throw "Host configuration not found: $configPath"
    }

    # Parse YAML using powershell-yaml module
    $content = Get-Content $configPath -Raw
    $yaml = ConvertFrom-Yaml $content

    # Extract settings from metadata section
    $metadata = $yaml.metadata

    # Build config with defaults, then overlay parsed YAML
    $config = @{
        hostname = if ($metadata.hostname) { $metadata.hostname } else { $HostName }
        debloat = @{
            enabled = if ($null -ne $metadata.debloat.enabled) { $metadata.debloat.enabled } else { $true }
            config = if ($metadata.debloat.config) { $metadata.debloat.config } else { "lib/winutil.json" }
        }
        dotfiles = @{
            enabled = if ($null -ne $metadata.dotfiles.enabled) { $metadata.dotfiles.enabled } else { $true }
            features = @{
                ricing = if ($null -ne $metadata.dotfiles.features.ricing) { $metadata.dotfiles.features.ricing } else { $false }
                development = if ($null -ne $metadata.dotfiles.features.development) { $metadata.dotfiles.features.development } else { $false }
                gaming = if ($null -ne $metadata.dotfiles.features.gaming) { $metadata.dotfiles.features.gaming } else { $false }
            }
        }
        user = @{
            name = if ($metadata.user.name) { $metadata.user.name } else { "" }
            email = if ($metadata.user.email) { $metadata.user.email } else { "" }
        }
    }

    return $config
}

function Install-Prerequisites {
    Write-Step "Checking Prerequisites"

    # Check for winget
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "WinGet is not installed. Please install App Installer from the Microsoft Store."
    }
    Write-Success "WinGet available"

    # Check for powershell-yaml module
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Info "Installing powershell-yaml module..."
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser -AllowClobber
    }
    Import-Module powershell-yaml -Force
    Write-Success "powershell-yaml available"

    # Check for DSC v3
    if (-not (Get-Command dsc -ErrorAction SilentlyContinue)) {
        Write-Info "Installing DSC v3 from Microsoft Store..."
        winget install --id 9NVTPZWRC6KQ --source msstore --accept-package-agreements --accept-source-agreements --disable-interactivity
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
    Write-Success "DSC v3 available"

    # Check for PowerShell 7 (required for DSC v3)
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        Write-Info "Installing PowerShell 7 (required for DSC v3)..."
        winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
    Write-Success "PowerShell 7 available"

    # Install DSC modules in PowerShell 7 (where DSC v3 looks for them)
    Write-Info "Ensuring DSC modules are installed in PowerShell 7..."
    pwsh -NoProfile -Command {
        if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.DSC)) {
            Install-Module -Name Microsoft.WinGet.DSC -Force -Scope CurrentUser -AllowClobber -AllowPrerelease
        }
        if (-not (Get-Module -ListAvailable -Name Microsoft.Windows.Developer)) {
            Install-Module -Name Microsoft.Windows.Developer -Force -Scope CurrentUser -AllowClobber -AllowPrerelease
        }
        if (-not (Get-Module -ListAvailable -Name Microsoft.VSCode.Dsc)) {
            Install-Module -Name Microsoft.VSCode.Dsc -Force -Scope CurrentUser -AllowClobber -AllowPrerelease
        }
    }
    Write-Success "DSC modules available"

    # Check for chezmoi (needed for dotfiles)
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        Write-Info "Installing Chezmoi..."
        winget install --id twpayne.chezmoi --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
    Write-Success "Chezmoi available"
}

function Apply-DscConfig {
    param([string]$HostName)

    $configPath = Join-Path $ConfigRoot "hosts\$HostName.dsc.config.yaml"

    Write-Info "Applying DSC v3 configuration: $configPath"

    # Use DSC v3 to apply the configuration
    # The config uses Microsoft.DSC/Include to pull in profile configs
    # Must run from hosts/ directory so relative includes work
    Push-Location (Join-Path $ConfigRoot "hosts")
    try {
        # Use --trace-level warn for less noise (use debug/trace for troubleshooting)
        dsc --trace-level warn config set --file $configPath
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            Write-Warning "DSC configuration had errors (exit code: $exitCode)"
            return $false
        }

        Write-Success "DSC configuration applied"
        return $true
    }
    finally {
        Pop-Location
    }
}

function Apply-Debloat {
    param([string]$ConfigPath)

    $fullPath = Join-Path $ConfigRoot $ConfigPath

    Write-Info "Applying WinUtil debloat from: $fullPath"
    Write-Info "WinUtil will open in a separate window - close it when finished"

    # Run WinUtil in a separate PowerShell process (non-blocking)
    # Using encoded command to avoid escaping issues
    $script = "iex `"& { `$(irm 'https://christitus.com/win') } -Config '$fullPath' -Run`""
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($script)
    $encoded = [Convert]::ToBase64String($bytes)
    Start-Process powershell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encoded

    Write-Success "WinUtil started (runs in background)"
}

function Apply-Dotfiles {
    param([hashtable]$Features)

    $homePath = Join-Path $ConfigRoot "home"

    Write-Info "Applying dotfiles via Chezmoi"
    Write-Info "  Features: ricing=$($Features.ricing), development=$($Features.development), gaming=$($Features.gaming)"

    # Initialize and apply chezmoi
    chezmoi init --source $homePath --apply --force
    Write-Success "Dotfiles applied"
}

function Install-VsCodeExtensions {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Warning "VS Code not installed, skipping extensions"
        return
    }

    Write-Info "Installing VS Code extensions..."

    $extensions = @(
        "catppuccin.catppuccin-vsc"
        "catppuccin.catppuccin-vsc-icons"
        "eamodio.gitlens"
        "mhutchie.git-graph"
        "esbenp.prettier-vscode"
        "usernamehw.errorlens"
        "gruntfuggly.todo-tree"
    )

    foreach ($ext in $extensions) {
        Write-Info "  - $ext"
        code --install-extension $ext --force 2>&1 | Out-Null
    }

    Write-Success "VS Code extensions installed"
}

# ============================================
# Main Execution
# ============================================

Write-Host ""
Write-Host "Windows Declarative Configuration (DSC v3)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Determine hostname
if (-not $HostName) {
    $HostName = $env:COMPUTERNAME.ToLower()
    # Check if host config exists, otherwise use default
    if (-not (Test-Path (Join-Path $ConfigRoot "hosts\$HostName.dsc.config.yaml"))) {
        $HostName = "demon"
    }
}

Write-Host "Host: $HostName" -ForegroundColor Gray

# Check admin rights (not required for DotfilesOnly)
if (-not $DotfilesOnly -and -not (Test-Administrator)) {
    Write-Host "`nERROR: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Install prerequisites
Install-Prerequisites

# Load host configuration (for debloat/dotfiles settings)
Write-Step "Loading Configuration"
try {
    $hostConfig = Get-HostConfig -HostName $HostName
    Write-Success "Loaded config for: $($hostConfig.hostname)"
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}

# Apply debloat (only if -Debloat flag is passed)
if ($Debloat -and -not $ProfilesOnly -and -not $DotfilesOnly -and $hostConfig.debloat.enabled) {
    Write-Step "Applying System Debloat"
    Apply-Debloat -ConfigPath $hostConfig.debloat.config
} elseif (-not $DotfilesOnly) {
    Write-Step "System Debloat"
    Write-Skip "Debloat skipped (use -Debloat flag to run)"
}

# Apply DSC v3 configuration (includes all profiles via Microsoft.DSC/Include)
if (-not $DotfilesOnly) {
    Write-Step "Applying DSC v3 Configuration"
    $dscSuccess = Apply-DscConfig -HostName $HostName

    if (-not $dscSuccess) {
        Write-Host "`nERROR: DSC configuration failed. Stopping." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Step "DSC Configuration"
    Write-Skip "DSC skipped (DotfilesOnly mode)"
}

# Apply dotfiles
if (-not $SkipDotfiles -and -not $ProfilesOnly -and $hostConfig.dotfiles.enabled) {
    Write-Step "Applying Dotfiles"
    Apply-Dotfiles -Features $hostConfig.dotfiles.features
} else {
    Write-Step "Dotfiles"
    Write-Skip "Dotfiles skipped"
}

# Install VS Code extensions (if development enabled)
if ($hostConfig.dotfiles.features.development -and -not $ProfilesOnly) {
    Write-Step "VS Code Extensions"
    Install-VsCodeExtensions
}

# Summary
Write-Step "Summary" "Green"
Write-Host ""
if ($DotfilesOnly) {
    Write-Host "  Dotfiles: [OK]" -ForegroundColor Green
} else {
    Write-Host "  DSC Configuration: [OK]" -ForegroundColor Green
    if (-not $SkipDotfiles -and -not $ProfilesOnly) {
        Write-Host "  Dotfiles: [OK]" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "  Configuration applied successfully!" -ForegroundColor Green
Write-Host "  Restart your terminal or PC for all changes to take effect." -ForegroundColor Cyan
Write-Host ""
