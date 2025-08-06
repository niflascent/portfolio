# Define the action: run both scripts sequentially, authenticating with Managed Identity
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -WindowStyle Hidden -Command "& {Connect-AzAccount -Identity; C:\AzViz\generate-azviz-full.ps1; C:\AzViz\generate-azviz-rg.ps1}"'

# Define the trigger: Daily at 01:00
$Trigger = New-ScheduledTaskTrigger -Daily -At 1:00am

# Define principal: run with SYSTEM account so it works when no user is logged in
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName "DailyAzVizDiagrams" -Action $Action -Trigger $Trigger -Principal $Principal -Description "Run AzViz diagram scripts daily at 01:00 using VM Managed Identity"

