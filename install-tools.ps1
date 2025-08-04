# install-tools.ps1

# Allow script to run without interruption
Set-ExecutionPolicy Bypass -Scope Process -Force

# Ensure TLS 1.2 or above for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install Chocolatey (Windows package manager)
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Refresh environment variables for choco without restarting
$env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"

# Install required software silently
choco install graphviz vscode terraform -y

# Install PowerShell Az module (for Azure CLI cmdlets)
Install-Module -Name Az -Force -AllowClobber -Scope AllUsers

# Install AzViz module (for Azure visualization)
Install-Module -Name AzViz -Force -Scope AllUsers