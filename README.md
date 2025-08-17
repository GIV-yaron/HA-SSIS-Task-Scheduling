# Task Scheduler Health Check Script

This PowerShell script performs a health check on Task Scheduler jobs on a remote server, updates the active server in a SQL Server table if needed, and executes an SSIS package. It also logs all actions and results to a log file.

## 📋 Description

- Queries the `activeserver` from the `jobcontrol` SQL Server table.
- Checks the health of scheduled tasks on the active server.
- If the active server is unhealthy, updates the `activeserver` to the current server.
- Executes an SSIS package using `dtexec`.
- Logs all operations to a specified log file.

## ⚙️ Prerequisites

- PowerShell 5.1 or later
- SQL Server PowerShell module (`SqlServer`)
- Access to the SQL Server database containing the `jobcontrol` table
- `dtexec` utility installed (part of SQL Server Integration Services)
- Proper permissions to query/update SQL Server and execute scheduled tasks

## 🚀 Usage

Update the script parameters as needed:

```powershell
param (
    [string]$SqlServer = "YourSqlServerName",
    [string]$Database = "YourDatabaseName",
    [string]$SqlUser = "YourSqlUsername",
    [string]$SqlPassword = "YourSqlPassword",
    [string]$CurrentServer = $env:COMPUTERNAME,
    [string]$SsisPackagePath = "C:\\Path\\To\\YourPackage.dtsx",
    [string]$LogFile = "C:\\Logs\\TaskSchedulerHealthCheck.log"
)
