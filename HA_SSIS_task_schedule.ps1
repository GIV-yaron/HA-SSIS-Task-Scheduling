param (
    [string]$SqlServer = "YourSqlServerName",
    [string]$Database = "YourDatabaseName",
    [string]$SqlUser = "YourSqlUsername",
    [string]$SqlPassword = "YourSqlPassword",
    [string]$CurrentServer = $env:COMPUTERNAME,
    [string]$SsisPackagePath = "C:\Path\To\YourPackage.dtsx",
    [string]$LogFile = "C:\Logs\TaskSchedulerHealthCheck.log"
)

Import-Module SqlServer -ErrorAction SilentlyContinue

function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $Message"
    Add-Content -Path $LogFile -Value $entry
    Write-Host $entry
}

Write-Log "Starting health check script..."

$connectionString = "Server=$SqlServer;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;Trusted_Connection=False;"
$queryGet = "SELECT TOP 1 activeserver FROM jobcontrol"
$activeServer = Invoke-Sqlcmd -ConnectionString $connectionString -Query $queryGet | Select-Object -ExpandProperty activeserver

Write-Log "Active server in DB: $activeServer"
Write-Log "Current server: $CurrentServer"

function Is-TaskSchedulerHealthy {
    param (
        [string]$ComputerName
    )

    try {
        $tasks = Get-ScheduledTask -CimSession $ComputerName
        foreach ($task in $tasks) {
            $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -CimSession $ComputerName
            if ($info.LastTaskResult -ne 0) {
                Write-Log "Task $($task.TaskName) failed with result $($info.LastTaskResult)"
                return $false
            }
        }
        return $true
    } catch {
        Write-Log "Error checking tasks on $ComputerName: $_"
        return $false
    }
}

$health = Is-TaskSchedulerHealthy -ComputerName $activeServer

if (-not $health) {
    Write-Log "Active server is not healthy. Updating to $CurrentServer..."
    $queryUpdate = "UPDATE jobcontrol SET activeserver = '$CurrentServer'"
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $queryUpdate
    $activeServer = $CurrentServer
    Write-Log "Active server updated to $CurrentServer."
} else {
    Write-Log "Active server is healthy. No update needed."
}

Write-Log "Executing SSIS package on $activeServer..."
$dtexecCmd = "dtexec /f `"$SsisPackagePath`""
try {
    Invoke-Expression $dtexecCmd
    Write-Log "SSIS package executed successfully."
} catch {
    Write-Log "Error executing SSIS package: $_"
}

Write-Log "Script completed."
