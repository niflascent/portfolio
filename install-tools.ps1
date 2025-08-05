# install-tools.ps1
# Version 2.1 20250805
# Idempotent Installer
# Run as Administrator

# Setup logging folder
$LogFolder = "C:\install-tools\logging"
if (-not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}
$LogFile = Join-Path $LogFolder ("install-tools_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

# Function to log both to console and file
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "$Timestamp`t$Message"
    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry
}

Write-Log "=== Starting tool installation (Idempotent & Fully Automated) ==="

# Function to install or upgrade a Chocolatey package
function Ensure-ChocoPackage {
    param(
        [Parameter(Mandatory = $true)][string]$PackageName
    )
    if (choco list --localonly | Select-String -Pattern $PackageName) {
        Write-Log "$PackageName already installed. Upgrading..."
        choco upgrade $PackageName -y --no-progress | Tee-Object -FilePath $LogFile -Append
    } else {
        Write-Log "Installing $PackageName..."
        choco install $PackageName -y --no-progress | Tee-Object -FilePath $LogFile -Append
    }
}

# Function to install Chocolatey
function Ensure-Choco {
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        refreshenv
        Write-Log "Chocolatey installed."
    } else {
        Write-Log "Chocolatey already installed."
    }
}

# Ensure Chocolatey
Ensure-Choco

# Ensure VS Code
Ensure-ChocoPackage -PackageName "vscode"

# Ensure Terraform
Ensure-ChocoPackage -PackageName "terraform"

# Ensure Graphviz
Ensure-ChocoPackage -PackageName "graphviz"

# Ensure NuGet provider without prompt
Write-Log "Ensuring NuGet provider..."
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Log "Installing NuGet provider silently..."
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers | Out-File -Append -FilePath $LogFile
}
# Suppress untrusted repo prompt by trusting PSGallery
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Ensure Az Module
Write-Log "Ensuring Az PowerShell module..."
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -AllowClobber -Force -Scope AllUsers -Confirm:$false | Out-File -Append -FilePath $LogFile
    Write-Log "Az module installed."
} else {
    Update-Module -Name Az -Force -Confirm:$false | Out-File -Append -FilePath $LogFile
    Write-Log "Az module updated."
}

# Ensure AzViz Module
Write-Log "Ensuring AzViz module..."
if (-not (Get-Module -ListAvailable -Name AzViz)) {
    Install-Module -Name AzViz -AllowClobber -Force -Scope AllUsers -Confirm:$false | Out-File -Append -FilePath $LogFile
    Write-Log "AzViz module installed."
} else {
    Update-Module -Name AzViz -Force -Confirm:$false | Out-File -Append -FilePath $LogFile
    Write-Log "AzViz module updated."
}

Write-Log "=== Installation Complete ==="

# Verification output
Write-Log "=== Installed Versions ==="
try { Write-Log "VS Code: $(code --version)" } catch { Write-Log "VS Code not found" }
try { Write-Log "Terraform: $(terraform -version)" } catch { Write-Log "Terraform not found" }
try { Write-Log "Graphviz: $(dot -V)" } catch { Write-Log "Graphviz not found" }
try { Get-Module -ListAvailable Az* | Select-Object Name, Version | Out-String | ForEach-Object { Write-Log $_ } } catch { Write-Log "Az module not found" }
try { Get-Module -ListAvailable AzViz | Select-Object Name, Version | Out-String | ForEach-Object { Write-Log $_ } } catch { Write-Log "AzViz not found" }

Write-Log "=== Script finished successfully ==="
