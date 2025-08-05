# install-tools.ps1
# Version 2.4 20250806
# Idempotent Installer
# Run as Administrator

$ErrorActionPreference = "Stop"

# Ensure logging folder exists
$logDir = "C:\install-tools\logging"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}
Start-Transcript -Path "$logDir\install-tools.log" -Append

Write-Output "=== Starting tool installation ==="

# Force TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Ensure NuGet provider is installed silently
Write-Output "Ensuring NuGet provider - start"
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers
}
Write-Output "Ensuring NuGet provider - complete"

# Install Git if not installed
if (-not (Get-Command "git.exe" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Git..."
    winget install --id Git.Git -e --silent
} else {
    Write-Output "Git already installed"
}

# Install GitHub CLI (gh) using Winget
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    try {
        Write-Output "Installing GitHub CLI via Winget..."
        winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements | Out-Null
        Write-Output "GitHub CLI installed."
    }
    catch {
        Write-Output "Failed to install GitHub CLI via Winget: $($_.Exception.Message)"
    }
} else {
    Write-Output "GitHub CLI already installed."
}

# Install Azure CLI
if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Azure CLI..."
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile "$env:TEMP\AzureCLI.msi" -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i `"$env:TEMP\AzureCLI.msi`" /quiet /norestart" -Wait
    Remove-Item "$env:TEMP\AzureCLI.msi" -Force
    Write-Output "Azure CLI installed."
} else {
    Write-Output "Azure CLI already installed."
}

# Install Bicep CLI
if (-not (Get-Command "bicep" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Bicep CLI..."
    $bicepDir = "C:\Program Files\BicepCLI"
    if (-not (Test-Path $bicepDir)) { New-Item -ItemType Directory -Path $bicepDir | Out-Null }
    Invoke-WebRequest -Uri "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe" -OutFile "$bicepDir\bicep.exe" -UseBasicParsing
    $env:PATH += ";$bicepDir"
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$bicepDir", [EnvironmentVariableTarget]::Machine)
    Write-Output "Bicep CLI installed."
} else {
    Write-Output "Bicep CLI already installed."
}

# Install Terraform
if (-not (Get-Command "terraform" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Terraform..."
    $terraformZip = "$env:TEMP\terraform.zip"
    Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_windows_amd64.zip" -OutFile $terraformZip -UseBasicParsing
    Expand-Archive $terraformZip -DestinationPath "C:\Terraform" -Force
    Remove-Item $terraformZip -Force
    $env:PATH += ";C:\Terraform"
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Terraform", [EnvironmentVariableTarget]::Machine)
    Write-Output "Terraform installed."
} else {
    Write-Output "Terraform already installed."
}

# Install Visual Studio Code
if (-not (Get-Command "code" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Visual Studio Code..."
    winget install --id Microsoft.VisualStudioCode -e --silent
} else {
    Write-Output "Visual Studio Code already installed."
}

# Install PowerShell modules
Write-Output "Installing Az module..."
Install-Module -Name Az -AllowClobber -Force -Scope AllUsers
Write-Output "Installing AzViz module..."
Install-Module -Name AzViz -Force -Scope AllUsers
Write-Output "Installing AzureAD module..."
Install-Module -Name AzureAD -Force -Scope AllUsers
Write-Output "Installing Microsoft.Graph module..."
Install-Module -Name Microsoft.Graph -Force -Scope AllUsers

# Display installed versions
Write-Output "===== Version Information ====="
if (Get-Module -ListAvailable -Name Az) { Write-Output "Az: v$((Get-InstalledModule Az).Version)" }
if (Get-Module -ListAvailable -Name AzViz) { Write-Output "AzViz: v$((Get-InstalledModule AzViz).Version)" }
if (Get-Module -ListAvailable -Name AzureAD) { Write-Output "AzureAD: v$((Get-InstalledModule AzureAD).Version)" }
if (Get-Module -ListAvailable -Name Microsoft.Graph) { Write-Output "Microsoft.Graph: v$((Get-InstalledModule Microsoft.Graph).Version)" }
if (Get-Command "bicep" -ErrorAction SilentlyContinue) { Write-Output "Bicep CLI: $(bicep --version)" }
if (Get-Command "terraform" -ErrorAction SilentlyContinue) { Write-Output "Terraform: $(terraform -version | Select-Object -First 1)" }
if (Get-Command "az" -ErrorAction SilentlyContinue) { Write-Output "Azure CLI: $(az version | ConvertTo-Json -Compress)" }
if (Get-Command "gh" -ErrorAction SilentlyContinue) { Write-Output "GitHub CLI: $(gh --version)" }
Write-Output "===== End of Version Information ====="

Stop-Transcript
