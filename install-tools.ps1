# install-tools.ps1
# Version 2.2 20250806
# Idempotent Installer
# Run as Administrator

# Create logging directory
$logPath = "C:\install-tools\logging"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}

# Start logging
$logFile = Join-Path $logPath "install-tools.log"
Start-Transcript -Path $logFile -Append

# Trust PSGallery repository to avoid prompt
try {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
} catch {
    Write-Output "Failed to set PSGallery repository as trusted. Continuing..."
}

# Ensure NuGet provider is installed silently
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
}

# Import NuGet provider
Import-PackageProvider -Name NuGet -Force

# Helper function to install modules silently
function Install-ModuleSafe {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Output "Installing module: $ModuleName"
        try {
            Install-Module -Name $ModuleName -Force -AllowClobber -Scope AllUsers -Confirm:$false
            Write-Output "Installed module: $ModuleName"
        } catch {
            Write-Output "Failed to install module: $ModuleName. $_"
        }
    } else {
        Write-Output "Module already installed: $ModuleName"
    }
}

# Install required PowerShell modules
$modules = @("Az.Accounts", "Az.Resources", "AzViz")

foreach ($mod in $modules) {
    Install-ModuleSafe -ModuleName $mod
}

# Install Terraform
try {
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Terraform"
        Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/1.9.2/terraform_1.9.2_windows_amd64.zip" -OutFile "$env:TEMP\terraform.zip"
        Expand-Archive -Path "$env:TEMP\terraform.zip" -DestinationPath "C:\terraform" -Force
        $envPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
        if ($envPath -notlike "*C:\terraform*") {
            [Environment]::SetEnvironmentVariable("Path", $envPath + ";C:\terraform", [EnvironmentVariableTarget]::Machine)
            Write-Output "Added Terraform to system PATH"
        }
    } else {
        Write-Output "Terraform already installed"
    }
} catch {
    Write-Output "Failed to install Terraform: $_"
}

# Install Visual Studio Code (if not installed)
try {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Visual Studio Code"
        $vscodeInstaller = "$env:TEMP\VSCodeSetup.exe"
        Invoke-WebRequest -Uri "https://update.code.visualstudio.com/latest/win32-x64-user/stable" -OutFile $vscodeInstaller
        Start-Process -FilePath $vscodeInstaller -ArgumentList "/silent","/mergetasks=!runcode" -Wait
        Remove-Item $vscodeInstaller -Force
    } else {
        Write-Output "Visual Studio Code already installed"
    }
} catch {
    Write-Output "Failed to install Visual Studio Code: $_"
}

Stop-Transcript
