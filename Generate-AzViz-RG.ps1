# Invokes AzViz to create basic diagram of Azure resources per RG
# Includes rudimentary versioning based on run date/time

param(
    [string]$SubscriptionName
)

# Root output folder
$RootOutputDir = "C:\AzViz\Out"

# Ensure root folder exists
if (-not (Test-Path $RootOutputDir)) {
    New-Item -ItemType Directory -Path $RootOutputDir -Force | Out-Null
}

# Create a session-specific subfolder with datetime stamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$SessionOutputDir = Join-Path $RootOutputDir "RG_$timestamp"
New-Item -ItemType Directory -Path $SessionOutputDir -Force | Out-Null

Write-Host "▶ Output folder for this run: $SessionOutputDir" -ForegroundColor Yellow

# Connect to Azure and set subscription context
# Connect-AzAccount -UseDeviceAuthentication
Connect-AzAccount -Identity

if ($SubscriptionName) {
    Set-AzContext -Subscription $SubscriptionName
}

# Get all resource groups
$resourceGroups = Get-AzResourceGroup

foreach ($rg in $resourceGroups) {
    $rgName = $rg.ResourceGroupName
    $outputFile = Join-Path $SessionOutputDir "$rgName.png"

    Write-Host "▶ Generating diagram for Resource Group: $rgName" -ForegroundColor Cyan

    try {
        Export-AzViz -ResourceGroup $rgName -OutputFormat png -OutputFilePath $outputFile -Theme light -ErrorAction Stop
        Write-Host "✔ Diagram saved: $outputFile" -ForegroundColor Green
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Warning "⚠ Failed on $rgName : $errorMessage"
    }
}

Write-Host "All done! Diagrams saved to $SessionOutputDir" -ForegroundColor Yellow

# --- Add cleanup block below this line ---

# Root output folder
$RootOutputDir = "C:\AzViz\Out"

# Keep only the last 30 days of diagrams
$DaysToKeep = 30
$CutoffDate = (Get-Date).AddDays(-$DaysToKeep)

Write-Host "▶ Cleaning up output folders older than $DaysToKeep days..." -ForegroundColor Yellow

Get-ChildItem -Path $RootOutputDir -Directory |
    Where-Object { $_.LastWriteTime -lt $CutoffDate } |
    ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Recurse -Force
            Write-Host "✔ Deleted old folder: $($_.FullName)" -ForegroundColor Green
        }
        catch {
            Write-Warning "⚠ Failed to delete folder: $($_.FullName). Error: $($_.Exception.Message)"
        }
    }