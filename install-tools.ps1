# install-tools.ps1
# Version 2.2 20250806
# Idempotent Installer
# Run as Administrator

# install-tools.ps1
# Enhanced version with improved NuGet provider install for SYSTEM context

$LogDir = "C:\install-tools\logging"
$LogFile = Join-Path $LogDir "install-tools.log"

if (!(Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force
}

function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Output $msg
}

Log "********** Starting install-tools.ps1 **********"

# Ensure TLS 1.2
try {
    Log "Setting TLS to 1.2"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    Log "Failed setting TLS 1.2: $_"
}

# Ensure NuGet provider installed for AllUsers, no prompt, no hang
try {
    Log "Ensuring NuGet provider - start"
    $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    if (-not $nugetProvider) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers -Confirm:$false -ErrorAction Stop
    }
    Import-PackageProvider -Name NuGet -Force -ErrorAction Stop
    Log "Ensured NuGet provider successfully"
} catch {
    Log "Error ensuring NuGet provider: $_"
    throw
}

# Ensure PowerShellGet module is updated
try {
    Log "Updating PowerShellGet module"
    Install-Module -Name PowerShellGet -Force -AllowClobber -Scope AllUsers -Confirm:$false -ErrorAction Stop
    Log "PowerShellGet module updated successfully"
} catch {
    Log "Failed to update PowerShellGet module: $_"
}

# Install Az PowerShell module (latest)
try {
    Log "Installing Az module"
    Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Confirm:$false -ErrorAction Stop
    Log "Az module installed successfully"
} catch {
    Log "Failed to install Az module: $_"
}

# Install Git
try {
    Log "Installing Git"
    choco install git -y --no-progress | Out-Null
    Log "Git installed successfully"
} catch {
    Log "Failed to install Git: $_"
}

# Install GitHub CLI
try {
    Log "Installing GitHub CLI"
    choco install github-cli -y --no-progress | Out-Null
    Log "GitHub CLI installed successfully"
} catch {
    Log "Failed to install GitHub CLI: $_"
}

# Install Azure CLI
try {
    Log "Installing Azure CLI"
    choco install azure-cli -y --no-progress | Out-Null
    Log "Azure CLI installed successfully"
} catch {
    Log "Failed to install Azure CLI: $_"
}

# Install Bicep CLI via Azure CLI
try {
    Log "Installing Bicep CLI"
    az bicep install --yes | Out-Null
    Log "Bicep CLI installed successfully"
} catch {
    Log "Failed to install Bicep CLI: $_"
}

# Install Terraform
try {
    Log "Installing Terraform"
    choco install terraform -y --no-progress | Out-Null
    Log "Terraform installed successfully"
} catch {
    Log "Failed to install Terraform: $_"
}

# Install Visual Studio Code
try {
    Log "Installing Visual Studio Code"
    choco install vscode -y --no-progress | Out-Null
    Log "Visual Studio Code installed successfully"
} catch {
    Log "Failed to install Visual Studio Code: $_"
}

Log "********** install-tools.ps1 completed **********"
