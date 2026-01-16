# Windows Dotfiles Bootstrap Script
# Usage: irm https://raw.githubusercontent.com/AddG0/windows-config/main/bootstrap.ps1 | iex

param(
    [string]$HostName = "demon-windows",
    [string]$UserName = "addg",
    [string]$RepoUrl = "https://github.com/AddG0/windows-config",
    [switch]$SkipDebloat
)

$ErrorActionPreference = "Stop"
$DotfilesPath = "$env:USERPROFILE\.dotfiles\windows"

Write-Host "=== Windows Dotfiles Bootstrap ===" -ForegroundColor Cyan
Write-Host "Host: $HostName | User: $UserName" -ForegroundColor Gray

# Ensure running as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Run this script as Administrator!" -ForegroundColor Red
    exit 1
}

# Step 1: Install prerequisites
Write-Host "`n[1/5] Installing prerequisites..." -ForegroundColor Yellow

$packages = @(
    @{id = "Git.Git"; name = "Git"},
    @{id = "twpayne.chezmoi"; name = "Chezmoi"}
)

foreach ($pkg in $packages) {
    $installed = winget list --id $pkg.id 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Installing $($pkg.name)..." -ForegroundColor Gray
        winget install -e --id $pkg.id --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "  $($pkg.name) already installed" -ForegroundColor DarkGray
    }
}

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Step 2: Clone dotfiles repo
Write-Host "`n[2/5] Cloning dotfiles repository..." -ForegroundColor Yellow

if (Test-Path $DotfilesPath) {
    Write-Host "  Dotfiles already exist, pulling latest..." -ForegroundColor Gray
    Push-Location $DotfilesPath
    git pull
    Pop-Location
} else {
    git clone $RepoUrl $DotfilesPath
}

# Step 3: Apply system-level configuration (debloat)
if (-not $SkipDebloat) {
    Write-Host "`n[3/5] Applying system configuration (WinUtil debloat)..." -ForegroundColor Yellow

    $hostConfig = "$DotfilesPath\hosts\windows\$HostName\winutil.json"
    $defaultConfig = "$DotfilesPath\hosts\common\core\winutil.json"

    $configToUse = if (Test-Path $hostConfig) { $hostConfig } else { $defaultConfig }

    if (Test-Path $configToUse) {
        Write-Host "  Using config: $configToUse" -ForegroundColor Gray
        iex "& { $(irm christitus.com/win) } -Config `"$configToUse`" -Run"
    } else {
        Write-Host "  No WinUtil config found, skipping debloat" -ForegroundColor DarkGray
    }
} else {
    Write-Host "`n[3/5] Skipping debloat (--SkipDebloat)" -ForegroundColor DarkGray
}

# Step 4: Install applications via WinGet DSC
Write-Host "`n[4/5] Installing applications..." -ForegroundColor Yellow

$appConfigs = @(
    "$DotfilesPath\hosts\common\core\apps.winget",
    "$DotfilesPath\hosts\windows\$HostName\apps.winget",
    "$DotfilesPath\home\common\optional\ricing\apps.winget",
    "$DotfilesPath\home\primary\$HostName\apps.winget"
)

foreach ($config in $appConfigs) {
    if (Test-Path $config) {
        Write-Host "  Applying: $config" -ForegroundColor Gray
        winget configure $config --accept-configuration-agreements
    }
}

# Step 5: Apply user dotfiles via Chezmoi
Write-Host "`n[5/5] Applying user dotfiles..." -ForegroundColor Yellow

# Initialize chezmoi with the home subdirectory
chezmoi init --source "$DotfilesPath\home" --apply

Write-Host "`n=== Bootstrap Complete ===" -ForegroundColor Green
Write-Host "Restart your terminal or PC for all changes to take effect." -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Sign into 1Password and enable SSH agent" -ForegroundColor Gray
Write-Host "  2. Start GlazeWM: Alt+Enter to open terminal" -ForegroundColor Gray
Write-Host "  3. Set GlazeWM to run at startup" -ForegroundColor Gray
