# PowerShell Profile
# Managed by Chezmoi - do not edit directly

# Oh My Posh prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:USERPROFILE\.config\ohmyposh\theme.omp.json" | Invoke-Expression
}

# Aliases
Set-Alias -Name g -Value git
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

# Functions
function mkcd { param($dir) New-Item -ItemType Directory -Path $dir; Set-Location $dir }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }

# Environment
$env:EDITOR = "code --wait"

# 1Password SSH Agent (if available)
if (Test-Path "$env:LOCALAPPDATA\1Password\app\8\op-ssh-sign.exe") {
    $env:GIT_SSH_COMMAND = "C:/Windows/System32/OpenSSH/ssh.exe"
}

# PSReadLine configuration
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# Chezmoi helper
function dots { chezmoi $args }
function dotse { chezmoi edit $args }
function dotsa { chezmoi apply }
function dotsd { chezmoi diff }
