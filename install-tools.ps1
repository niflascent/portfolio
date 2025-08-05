# install-tools.ps1
# Version 2.2 20250806
# Idempotent Installer
# Run as Administrator

# Ensure logging directory exists
$logDir = "C:\install-tools\logging"
if (!(Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}
$logFile = Join-Path $logDir "install-tools.log"

Start-Transcript -Path $logFile -Append

Write-Output "Starting tool installation at $(Get-Date)"

# Ensure TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install NuGet provider silently
Write-Output "Ensuring NuGet provider..."
$nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nugetProvider) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
}

# Install Az PowerShell modules
Write-Output "Installing Az PowerShell modules..."
try {
    Install-Module -Name Az -AllowClobber -Force -Scope CurrentUser
} catch {
    Write-Output "Az module install failed: $_"
}

# Install Chocolatey if missing
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Ensure Chocolatey is available in this session
$env:Path += ";$($env:ALLUSERSPROFILE)\chocolatey\bin"

# Install Terraform
Write-Output "Installing Terraform..."
choco install terraform -y --no-progress

# Install Visual Studio Code
Write-Output "Installing Visual Studio Code..."
choco install vscode -y --no-progress

# Install Git (includes Git Credential Manager)
Write-Output "Installing Git..."
choco install git -y --no-progress

# Install GitHub CLI
Write-Output "Installing GitHub CLI..."
choco install gh -y --no-progress

# Install Azure CLI
Write-Output "Installing Azure CLI..."
choco install azure-cli -y --no-progress

# Install Bicep CLI via Azure CLI
Write-Output "Installing Bicep CLI..."
try {
    az bicep install
} catch {
    Write-Output "Failed to install Bicep: $_"
}

# Write a completion flag
$completionFlag = "C:\install-tools\logging\install-complete.txt"
"Install script completed successfully on $(Get-Date)" | Out-File -FilePath $completionFlag -Encoding UTF8 -Force

Write-Output "Tool installation finished at $(Get-Date)"
Stop-Transcript
