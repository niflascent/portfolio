Write-Output "=== Starting software verification ==="

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = git --version
    Write-Output "Git installed: $gitVersion"
} else {
    Write-Output "Git NOT installed or not in PATH."
}

# Terraform
if (Get-Command terraform -ErrorAction SilentlyContinue) {
    $tfVersion = terraform --version | Select-Object -First 1
    Write-Output "Terraform installed: $tfVersion"
} else {
    Write-Output "Terraform NOT installed or not in PATH."
}

# Visual Studio Code
if (Get-Command code -ErrorAction SilentlyContinue) {
    $codeVersion = code --version | Select-Object -First 1
    Write-Output "Visual Studio Code installed: $codeVersion"
} else {
    Write-Output "Visual Studio Code NOT installed or not in PATH."
}

# Bicep CLI
if (Get-Command bicep -ErrorAction SilentlyContinue) {
    $bicepVersion = bicep --version
    Write-Output "Bicep CLI installed: v$bicepVersion"
} else {
    Write-Output "Bicep CLI NOT installed or not in PATH."
}

# Azure CLI
if (Get-Command az -ErrorAction SilentlyContinue) {
    $azVersion = az --version | Select-Object -First 1
    Write-Output "Azure CLI installed: $azVersion"
} else {
    Write-Output "Azure CLI NOT installed or not in PATH."
}

# GitHub CLI
if (Get-Command gh -ErrorAction SilentlyContinue) {
    $ghVersion = gh --version | Select-Object -First 1
    Write-Output "GitHub CLI installed: $ghVersion"
} else {
    Write-Output "GitHub CLI NOT installed or not in PATH."
}

# PowerShell modules
$modules = @("Az", "AzViz", "AzureAD", "Microsoft.Graph")
foreach ($mod in $modules) {
    if (Get-Module -ListAvailable -Name $mod) {
        $ver = (Get-InstalledModule -Name $mod -ErrorAction SilentlyContinue).Version
        if ($ver) {
            Write-Output "$mod module installed: v$ver"
        } else {
            Write-Output "$mod module installed"
        }
    } else {
        Write-Output "$mod module NOT installed."
    }
}

Write-Output "=== Software verification completed ==="
