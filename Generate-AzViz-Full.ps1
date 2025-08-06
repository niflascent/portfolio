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
$SessionOutputDir = Join-Path $RootOutputDir "Full_$timestamp"
New-Item -ItemType Directory -Path $SessionOutputDir -Force | Out-Null

Write-Host "▶ Output folder for this run: $SessionOutputDir" -ForegroundColor Yellow

# Connect to Azure and set subscription context
# Connect-AzAccount #-UseDeviceAuthentication
Connect-AzAccount -Identity

if ($SubscriptionName) {
    Set-AzContext -Subscription $SubscriptionName
}

# Define resource groups to exclude
$ExcludedRGs = @("NetworkWatcherRG", "DefaultResourceGroup-EUS", "DefaultResourceGroup-WUS")

# Get all resource groups except excluded ones
$resourceGroups = Get-AzResourceGroup | Where-Object { $ExcludedRGs -notcontains $_.ResourceGroupName }
$rgNames = $resourceGroups.ResourceGroupName

Write-Host "▶ Found $($rgNames.Count) resource groups (excluding: $($ExcludedRGs -join ', '))." -ForegroundColor Cyan

# Holistic diagram across all included RGs
$holisticFile = Join-Path $SessionOutputDir "FullEnvironment.png"

Write-Host "▶ Generating holistic diagram for all resource groups..." -ForegroundColor Cyan

try {
    Export-AzViz -ResourceGroup $rgNames -OutputFormat png -OutputFilePath $holisticFile -Theme light -ErrorAction Stop
    Write-Host "✔ Holistic diagram saved: $holisticFile" -ForegroundColor Green
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Warning "⚠ Failed to generate holistic diagram : $errorMessage"
}

Write-Host "All done! Check your diagrams in $SessionOutputDir" -ForegroundColor Yellow

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