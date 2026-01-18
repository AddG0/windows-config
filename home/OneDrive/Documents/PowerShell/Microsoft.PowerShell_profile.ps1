# PowerShell Profile
# Managed by Chezmoi - do not edit directly

# Oh My Posh prompt (config from nix-config repo)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "https://raw.githubusercontent.com/AddG0/nix-config/main/home/common/core/cli/themes/oh-my-posh/oh-my-posh-config-full.json" | Invoke-Expression
}

# Aliases
Set-Alias -Name g -Value git
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

# Remove conflicting built-in aliases
Remove-Alias -Name gc -Force -ErrorAction SilentlyContinue
Remove-Alias -Name gp -Force -ErrorAction SilentlyContinue
Remove-Alias -Name gl -Force -ErrorAction SilentlyContinue
Remove-Alias -Name gm -Force -ErrorAction SilentlyContinue

# Git functions (shell aliases)
function ga { git add $args }
function gaa { git add --all }
function gst { git status }
function gss { git status --short }
function gd { git diff $args }
function gds { git diff --staged $args }
function gc { git commit $args }
function gcm { param($msg) git commit -m $msg }
function gca { param($msg) git commit -am $msg }
function gco { git checkout $args }
function gcb { param($branch) git checkout -b $branch }
function gb { git branch $args }
function gba { git branch --all }
function gbd { git branch --delete $args }
function gl { git pull $args }
function gp { git push $args }
function gpf { git push --force-with-lease $args }
function gf { git fetch $args }
function gfa { git fetch --all --tags --prune }
function glog { git log --oneline --decorate --graph $args }
function gloga { git log --oneline --decorate --graph --all }
function grb { git rebase $args }
function grbi { git rebase --interactive $args }
function grbc { git rebase --continue }
function grba { git rebase --abort }
function gsta { git stash push $args }
function gstp { git stash pop }
function gstl { git stash list }
function gm { git merge $args }
function grh { git reset $args }
function grhh { git reset --hard $args }
function grhs { git reset --soft $args }

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
