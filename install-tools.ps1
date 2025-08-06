# install-tools.ps1
# Version 2.4 20250806
# Idempotent Installer
# Run as Administrator


# Ensure the logging directory exists
$logDir = "C:\install-tools\logging"
if (-not (Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Start transcript for detailed logging
Start-Transcript -Path "$logDir\install-tools.log" -Append

Write-Output "===== Starting install-tools script ====="

# Function to ensure NuGet provider silently and idempotently
Write-Output "Ensuring NuGet provider - start"
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    # Install NuGet silently
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
}
Import-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-Output "Ensuring NuGet provider - end"

# Install Chocolatey if missing (to help install GitHub CLI)
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    RefreshEnv
} else {
    Write-Output "Chocolatey is already installed."
}

# Helper function to install software idempotently via Chocolatey
function Install-ChocoPackage($pkgName) {
    if (-not (choco list --local-only | Select-String "^$pkgName ")) {
        Write-Output "Installing $pkgName..."
        choco install $pkgName -y --no-progress
    } else {
        Write-Output "$pkgName already installed."
    }
}

# Install GitHub CLI via Chocolatey
choco install gh -y

# Install other tools idempotently

# Git
choco install git -y

# Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Azure CLI..."
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile "$env:TEMP\AzureCLI.msi" -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList '/i', "$env:TEMP\AzureCLI.msi", '/quiet', '/norestart' -Wait
    Remove-Item "$env:TEMP\AzureCLI.msi" -Force
} else {
    Write-Output "Azure CLI already installed."
}

# Terraform
choco install terraform

# Visual Studio Code
choco install vscode

# Bicep CLI installation using Azure CLI (idempotent)
if (-not (Get-Command bicep -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Bicep CLI via Azure CLI..."
    az bicep install
} else {
    Write-Output "Bicep CLI already installed."
}

# Install PowerShell modules (idempotent)
$modules = @(
    @{ Name = "Az"; MinimumVersion = "6.4.0" },
    @{ Name = "AzViz"; MinimumVersion = "1.2.1" },
    @{ Name = "AzureAD"; MinimumVersion = "2.0.2" },
    @{ Name = "Microsoft.Graph"; MinimumVersion = "2.29.1" }
)

foreach ($mod in $modules) {
    $installed = Get-InstalledModule -Name $mod.Name -ErrorAction SilentlyContinue
    if (-not $installed) {
        Write-Output "Installing PowerShell module $($mod.Name)..."
        Install-Module -Name $mod.Name -MinimumVersion $mod.MinimumVersion -Force -AllowClobber -Scope AllUsers
    } else {
        Write-Output "PowerShell module $($mod.Name) already installed."
    }
}

# Final output of versions installed
Write-Output "===== Version Information ====="

$azModule = Get-Module -ListAvailable -Name Az | Sort-Object Version -Descending | Select-Object -First 1
if ($azModule) { Write-Output "Az: v$($azModule.Version)" } else { Write-Output "Az module NOT installed." }

$azvizModule = Get-Module -ListAvailable -Name AzViz | Sort-Object Version -Descending | Select-Object -First 1
if ($azvizModule) { Write-Output "AzViz: v$($azvizModule.Version)" } else { Write-Output "AzViz module NOT installed." }

$azureADModule = Get-Module -ListAvailable -Name AzureAD | Sort-Object Version -Descending | Select-Object -First 1
if ($azureADModule) { Write-Output "AzureAD: v$($azureADModule.Version)" } else { Write-Output "AzureAD module NOT installed." }

$graphModule = Get-Module -ListAvailable -Name Microsoft.Graph | Sort-Object Version -Descending | Select-Object -First 1
if ($graphModule) { Write-Output "Microsoft.Graph: v$($graphModule.Version)" } else { Write-Output "Microsoft.Graph module NOT installed." }

$bicepVersion = if (Get-Command bicep -ErrorAction SilentlyContinue) {
    (bicep --version) -replace '\r?\n',''
} else {
    "NOT installed or not in PATH."
}
Write-Output "Bicep CLI: $bicepVersion"

$terraformVersion = if (Get-Command terraform -ErrorAction SilentlyContinue) {
    (terraform -version | Select-String -Pattern '^Terraform v').Line.Trim()
} else {
    "NOT installed or not in PATH."
}
Write-Output "Terraform: $terraformVersion"

$gitVersion = if (Get-Command git -ErrorAction SilentlyContinue) {
    (git --version) -replace '\r?\n',''
} else {
    "NOT installed or not in PATH."
}
Write-Output "Git: $gitVersion"

$ghVersion = if (Get-Command gh -ErrorAction SilentlyContinue) {
    (gh --version | Select-String -Pattern '^gh version').Line.Trim()
} else {
    "NOT installed or not in PATH."
}
Write-Output "GitHub CLI: $ghVersion"

$azCliVersion = if (Get-Command az -ErrorAction SilentlyContinue) {
    (az --version | Select-String -Pattern '^azure-cli').Line.Trim()
} else {
    "NOT installed or not in PATH."
}
Write-Output "Azure CLI: $azCliVersion"

$codeVersion = if (Get-Command code -ErrorAction SilentlyContinue) {
    (code --version | Select-Object -First 1).Trim()
} else {
    "NOT installed or not in PATH."
}
Write-Output "Visual Studio Code: $codeVersion"

Write-Output "===== End of Version Information ====="

Write-Output "===== install-tools script completed ====="

Stop-Transcript
