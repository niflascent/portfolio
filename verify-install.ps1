Write-Host "=== Verifying Installed Components ===" -ForegroundColor Cyan

# Helper function for status
function Show-Result {
    param ($Name, $Result)
    if ($Result) {
        Write-Host "[OK] $Name installed: $Result" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $Name not found." -ForegroundColor Red
    }
}

# 1. Visual Studio Code
try {
    $codeVer = (code --version 2>$null) -join " "
    Show-Result "Visual Studio Code" $codeVer
} catch { Show-Result "Visual Studio Code" $null }

# 2. Terraform
try {
    $tfVer = (terraform --version 2>$null | Select-String "Terraform v").ToString()
    Show-Result "Terraform" $tfVer
} catch { Show-Result "Terraform" $null }

# 3. AzViz
$azviz = Get-Module -ListAvailable AzViz | Select-Object -First 1
Show-Result "AzViz" $($azviz.Version)

# 4. PowerShell Az Module
$azModule = Get-Module -ListAvailable Az.Accounts | Select-Object -First 1
Show-Result "PowerShell Az Module" $($azModule.Version)

# 5. NuGet Provider
$nuget = Get-PackageProvider -Name NuGet -ListAvailable 2>$null
Show-Result "NuGet Provider" $($nuget.Version)

# 6. Install Script Log
$logPath = "C:\install-tools\logging\install-tools.log"
if (Test-Path $logPath) {
    Write-Host "[OK] Install script log found at $logPath" -ForegroundColor Green
    Write-Host "---- Last 10 log lines ----"
    Get-Content $logPath | Select-Object -Last 10
} else {
    Write-Host "[MISSING] Install script log not found at $logPath" -ForegroundColor Red
}
