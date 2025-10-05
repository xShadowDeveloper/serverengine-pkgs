<#
.SYNOPSIS
Self-Healing Service Monitor
.DESCRIPTION
Restarts important services automatically if stopped.
.NOTES
Author: Claudio Orlando, CForce-IT
Website: https://serverengine.co
License: MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this script, to deal in the Script without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Script, and to permit persons to whom the Script is furnished to do so,
subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Script.
#>

$isadm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isadm) {
    Write-Host "<WRITE-LOG = ""*Please run this script as Administrator.*"">"
    Write-Error "Warning: Not running as Administrator."
    exit 1 
}

$CriticalServices = @(
    "Spooler",
    "wuauserv",
    "bits"
    )  # Modify as needed

foreach ($ServiceName in $CriticalServices) {
    try {
        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($null -eq $Service) { Write-Host "<WRITE-LOG = ""*Service: $ServiceName not found.*"">"; continue }

        if ($Service.Status -ne 'Running') {
            Write-Host "<WRITE-LOG = ""*Service: $ServiceName is $($Service.Status) - attempting restart...*"">"
            Restart-Service -Name $ServiceName -Force
            Start-Sleep 2
            $Service.Refresh()

            if ($Service.Status -eq 'Running') {
                Write-Host "<WRITE-LOG = ""*Service: $ServiceName restarted successfully.*"">"
            } else {
                Write-Host "<WRITE-LOG = ""*Service: $ServiceName failed to start.*"">"
            }
        } else {
            Write-Host "<WRITE-LOG = ""*Service: $ServiceName is running.*"">"
        }
    } catch {
        Write-Host "<WRITE-LOG = ""*Error checking Service: $ServiceName : $_*"">"
    }
}
