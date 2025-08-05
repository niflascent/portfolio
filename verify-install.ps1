# Path to log file
$logPath = "C:\install-tools\logging\verify-install.log"
if (!(Test-Path (Split-Path $logPath))) {
    New-Item -Path (Split-Path $logPath) -ItemType Directory -Force
}

function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logPath -Append -Encoding UTF8
    Write-Output $message
}

Log "=== Starting software verification ==="

# Check Git
try {
    $gitVersion = git --version
    Log "Git installed: $gitVersion"
} catch {
    Log "Git NOT installed or not in PATH."
}

# Check GitHub CLI (gh)
try {
    $ghVersion = gh --version
    Log "GitHub CLI installed: $ghVersion"
} catch {
    Log "GitHub CLI NOT installed or not in PATH."
}

# Check Azure CLI
try {
    $azVersion = az --version
    Log "Azure CLI installed: $($azVersion.Split("`n")[0])"
} catch {
    Log "Azure CLI NOT installed or not in PATH."
}

# Check Bicep CLI
try {
    $bicepVersion = az bicep version
    Log "Bicep CLI installed: $bicepVersion"
} catch {
    Log "Bicep CLI NOT installed or not accessible via Azure CLI."
}

# Check Terraform
try {
    $terraformVersion = terraform -version
    Log "Terraform installed: $($terraformVersion.Split("`n")[0])"
} catch {
    Log "Terraform NOT installed or not in PATH."
}

# Check VS Code
$vsCodePaths = @(
    "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
    "${env:LocalAppData}\Programs\Microsoft VS Code\Code.exe"
)

$vsCodeExists = $false
foreach ($path in $vsCodePaths) {
    if (Test-Path $path) {
        $vsCodeExists = $true
        break
    }
}
if ($vsCodeExists) {
    Log "Visual Studio Code installed."
} else {
    Log "Visual Studio Code NOT installed."
}

# Check PowerShell Az Module
try {
    Import-Module Az -ErrorAction Stop
    $azModules = Get-Module -Name Az* -ListAvailable
    if ($azModules) {
        $moduleList = $azModules | Select-Object -ExpandProperty Name -Unique | Sort-Object
        Log "Az PowerShell modules installed: $($moduleList -join ', ')"
    } else {
        Log "Az PowerShell modules NOT found."
    }
} catch {
    Log "Failed to load Az PowerShell modules."
}

Log "=== Software verification completed ==="
