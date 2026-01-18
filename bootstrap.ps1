# Windows Declarative Configuration Bootstrap
# Usage: irm https://raw.githubusercontent.com/AddG0/windows-config/main/bootstrap.ps1 | iex
#
# This script bootstraps a fresh Windows installation by:
# 1. Installing Git
# 2. Cloning this repository
# 3. Running Apply-Config.ps1

param(
    [string]$HostName = "demon",
    [string]$RepoUrl = "https://github.com/AddG0/windows-config",
    [string]$Branch = "main",
    [switch]$SkipDebloat
)

$ErrorActionPreference = "Stop"
$ConfigPath = "$env:USERPROFILE\windows-config"

Write-Host ""
Write-Host "Windows Declarative Configuration - Bootstrap" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Host: $HostName" -ForegroundColor Gray
Write-Host ""

# ============================================
# Check Administrator
# ============================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# ============================================
# Step 1: Install Git (if needed)
# ============================================
Write-Host "[1/4] Checking Git..." -ForegroundColor Yellow

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Git via WinGet..." -ForegroundColor Gray
    winget install -e --id Git.Git --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Git installation failed." -ForegroundColor Red
        exit 1
    }
}
Write-Host "  [OK] Git available" -ForegroundColor Green

# ============================================
# Step 2: Clone Repository
# ============================================
Write-Host "`n[2/4] Cloning configuration repository (HTTPS)..." -ForegroundColor Yellow

if (Test-Path $ConfigPath) {
    Write-Host "  Repository exists, pulling latest..." -ForegroundColor Gray
    Push-Location $ConfigPath
    git fetch origin
    git reset --hard "origin/$Branch"
    Pop-Location
} else {
    Write-Host "  Cloning from $RepoUrl..." -ForegroundColor Gray
    git clone --branch $Branch $RepoUrl $ConfigPath
}
Write-Host "  [OK] Repository ready at: $ConfigPath" -ForegroundColor Green

# ============================================
# Step 3: Run Apply-Config
# ============================================
Write-Host "`n[3/4] Applying configuration..." -ForegroundColor Yellow

$applyArgs = @("-Debloat")  # Run debloat on bootstrap
if ($HostName) { $applyArgs += "-HostName", $HostName }
if ($SkipDebloat) { $applyArgs = $applyArgs | Where-Object { $_ -ne "-Debloat" } }

& "$ConfigPath\Apply-Config.ps1" @applyArgs

# ============================================
# Step 4: Switch remote to SSH
# ============================================
Write-Host "`n[4/4] Switching remote to SSH..." -ForegroundColor Yellow
Push-Location $ConfigPath
$sshUrl = "git@github.com:AddG0/windows-config.git"
git remote set-url origin $sshUrl
Write-Host "  [OK] Remote switched to: $sshUrl" -ForegroundColor Green
Pop-Location

Write-Host ""
Write-Host "Bootstrap complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your terminal or PC" -ForegroundColor Gray
Write-Host "  2. Sign into 1Password and enable SSH agent (if not already)" -ForegroundColor Gray
Write-Host "  3. Run 'ssh -T git@github.com' to verify SSH works" -ForegroundColor Gray
Write-Host ""
Write-Host "To re-apply configuration:" -ForegroundColor Yellow
Write-Host "  cd $ConfigPath" -ForegroundColor Gray
Write-Host "  .\Apply-Config.ps1" -ForegroundColor Gray
Write-Host ""
