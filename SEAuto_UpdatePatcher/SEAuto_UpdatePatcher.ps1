<#
.SYNOPSIS
Patch Windows Updates
.DESCRIPTION
Detects and installes missing Windows updates.
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

try {
    Write-Host "<WRITE-LOG = ""*Checking for NuGet package provider...*"">"
    
    # Install NuGet provider if not present
    if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -WhatIf:$false -ErrorAction SilentlyContinue
        Write-Host "<WRITE-LOG = ""*NuGet package provider installed successfully*"">"
    } else {
        Write-Host "<WRITE-LOG = ""*NuGet package provider already available*"">"
    }

    Write-Host "<WRITE-LOG = ""*Installing PSWindowsUpdate module...*"">"
    
    # Install PSWindowsUpdate module
    $module = Get-Module -Name PSWindowsUpdate -ListAvailable
    if (!$module) {
        Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Confirm:$false -SkipPublisherCheck
        Write-Host "<WRITE-LOG = ""*PSWindowsUpdate module installed successfully*"">"
    } else {
        Write-Host "<WRITE-LOG = ""*PSWindowsUpdate module already installed*"">"
    }

    # Import the module
    Import-Module PSWindowsUpdate -Force
    Write-Host "<WRITE-LOG = ""*PSWindowsUpdate module imported*"">"

    Write-Host "<WRITE-LOG = ""*Searching for Windows Updates...*"">"
    
    # Get available updates with error handling
    try {
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
    } catch {
        Write-Host "<WRITE-LOG = ""*ERROR: Failed to search for updates: $($_.Exception.Message)*"">"
        exit 1
    }
        
    if ($updates.Count -gt 0) {
        Write-Host "<WRITE-LOG = ""*Found $($updates.Count) update(s) to install*"">"
        
        # Display update details
        $updates | ForEach-Object {
            Write-Host "<WRITE-LOG = ""*Update: $($_.Title) (KB$($_.KB))*"">"
        }

        Write-Host "<WRITE-LOG = ""*Installing Windows Updates...*"">"

        $scriptBlock = {
            try {
                Import-Module PSWindowsUpdate -Force
                
                # Hide problematic updates (expand this list as needed)
                $problematicKBs = @('KB5034439', 'KB5034441') # Add known problematic KBs here
                foreach ($kb in $problematicKBs) {
                    try {
                        $update = Get-WindowsUpdate -KBArticleID $kb -ErrorAction SilentlyContinue
                        if ($update) {
                            Hide-WindowsUpdate -KBArticleID $kb -Confirm:$false
                            Write-Output "Hidden problematic update: KB$kb"
                        }
                    } catch {
                        Write-Warning "Could not hide KB$kb : $($_.Exception.Message)"
                    }
                }
                
                # Get and install updates
                $updatesToInstall = Get-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll -AutoReboot:$false -IgnoreReboot
                
                # Stop any running PSWindowsUpdate scheduled tasks
                $runningTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like '*PSWindowsUpdate*' -and $_.State -eq 'Running' }
                foreach ($task in $runningTasks) {
                    try {
                        Stop-ScheduledTask -TaskName $task.TaskName -Confirm:$false
                    } catch {
                        Write-Warning "Could not stop task $($task.TaskName): $($_.Exception.Message)"
                    }
                }
                
            } catch {
                Write-Error "Update installation failed: $($_.Exception.Message)"
                exit 1
            }
        }  
        
        # Execute the update job
        try {
            $job = Invoke-WuJob -ComputerName $env:COMPUTERNAME -Script $scriptBlock -RunNow -Confirm:$false -ErrorAction Stop
            Write-Host "<WRITE-LOG = ""*Update job started successfully*"">"
        } catch {
            Write-Host "<WRITE-LOG = ""*ERROR: Failed to start update job: $($_.Exception.Message)*"">"
            exit 1
        }

        # Monitor update progress
        Write-Host "<WRITE-LOG = ""*Monitoring update progress...*"">"
        $timeout = 7200 # 120 minute timeout
        $timer = 0
        $checkInterval = 30 # seconds
        
        while ($timer -lt $timeout) {
            $runningTasks = Get-ScheduledTask | Where-Object { 
                $_.TaskName -like '*PSWindowsUpdate*' -and $_.State -eq 'Running' 
            }
            
            if ($runningTasks.Count -eq 0) {
                Write-Host "<WRITE-LOG = ""*Windows Updates installation completed!*"">"
                
                # Check if reboot is required
                $rebootRequired = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

                if ($rebootRequired) {
                    Write-Host "<WRITE-LOG = ""*System restart required*"">"
                } else {
                    Write-Host "<WRITE-LOG = ""*No restart required*"">"
                }
                break
            }
            
            Write-Host "<WRITE-LOG = ""*Updates in progress... ($timer seconds elapsed)*"">"
            Start-Sleep -Seconds $checkInterval
            $timer += $checkInterval
        }
        
        if ($timer -ge $timeout) {
            Write-Host "<WRITE-LOG = ""*WARNING: Update process timed out after $timeout seconds*"">"
        }
        
    } else {
        Write-Host "<WRITE-LOG = ""*System is up to date.*"">"
    }
    
} catch {
    Write-Host "<WRITE-LOG = ""*CRITICAL ERROR: $($_.Exception.Message)*"">"
    exit 1
} finally {
    # Cleanup - remove module if needed
    Remove-Module PSWindowsUpdate -ErrorAction SilentlyContinue
    Write-Host "<WRITE-LOG = ""*Updates completed*"">"
}