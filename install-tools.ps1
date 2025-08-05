# install-tools.ps1
# Version 2.4 20250806
# Idempotent Installer
# Run as Administrator

# Create logging folder and start transcript
$logFolder = "C:\install-tools\logging"
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}
$logFile = Join-Path $logFolder "install-tools.log"
Start-Transcript -Path $logFile -Append

Write-Output "**********************"
Write-Output "Starting install-tools.ps1"

# Ensure NuGet provider installed silently without prompts
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Output "Installing NuGet provider silently..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -Scope CurrentUser -ErrorAction Stop
}

# Import PackageManagement module explicitly
Import-Module PackageManagement

# Function to install a module if missing
function Install-ModuleIfMissing {
    param(
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Output "Installing PowerShell module $ModuleName..."
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber
    } else {
        Write-Output "PowerShell module $ModuleName already installed"
    }
}

# Install Chocolatey if not installed
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Chocolatey package manager..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Output "Chocolatey already installed"
}

# Install software with Chocolatey if missing
$chocoPackages = @("vscode", "git", "terraform")

foreach ($pkg in $chocoPackages) {
    if (-not (Get-Command $pkg -ErrorAction SilentlyContinue)) {
        Write-Output "Installing $pkg via Chocolatey..."
        choco install $pkg -y --no-progress
    } else {
        Write-Output "$pkg already installed"
    }
}

# Install PowerShell modules
Install-ModuleIfMissing -ModuleName "Az"
Install-ModuleIfMissing -ModuleName "AzViz"
Install-ModuleIfMissing -ModuleName "AzureAD"
Install-ModuleIfMissing -ModuleName "Microsoft.Graph"

# Install Bicep CLI if not present
if (-not (Get-Command bicep -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Bicep CLI..."
    Invoke-Expression "& { $(Invoke-RestMethod -Uri https://aka.ms/install-bicep.ps1) }"
} else {
    Write-Output "Bicep CLI already installed"
}

Write-Output "All installations complete."

Stop-Transcript


