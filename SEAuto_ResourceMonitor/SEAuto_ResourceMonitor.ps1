<#
.SYNOPSIS
System Resource Monitor
.DESCRIPTION
Displays overall CPU, RAM and Disk usage
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

# Get CPU usage
$cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time'
$cpuUsageValue = [math]::Round($cpuUsage.CounterSamples[0].CookedValue, 2)
$cpuCores = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors

# Get RAM usage
$ram = Get-WmiObject Win32_OperatingSystem
$totalRam = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
$freeRam = [math]::Round($ram.FreePhysicalMemory / 1MB, 2)
$usedRam = $totalRam - $freeRam
$ramUsagePercent = [math]::Round(($usedRam / $totalRam) * 100, 2)

# Get filesystem statistics
$filesystems = Get-PSDrive -PSProvider FileSystem | Select-Object Name, 
    @{Name='Used (GB)';Expression={[math]::Round($_.Used / 1GB, 2)}}, 
    @{Name='Free (GB)';Expression={[math]::Round($_.Free / 1GB, 2)}}, 
    @{Name='Total (GB)';Expression={[math]::Round(($_.Used + $_.Free) / 1GB, 2)}}

# Calculate usage percentage and include 100% total size
$filesystemUsage = $filesystems | Select-Object Name, 
    @{Name='Usage(%)';Expression={
        if ($_.'Used (GB)' -ne 0 -and $_.'Total (GB)' -ne 0) {
            [math]::Round(($_.'Used (GB)' / $_.'Total (GB)') * 100, 2)
        } else {
            0
        }
    }},
    @{Name='Used(GB)';Expression={$_. 'Used (GB)'}},  # Display used space in GB
    @{Name='Total(GB)';Expression={$_. 'Total (GB)'}}
# Output results
Write-Host "<WRITE-LOG = ""*CPU Usage: $cpuUsageValue% Total Processors: $cpuCores*"">"
Write-Host "<WRITE-LOG = ""*RAM Usage: $ramUsagePercent% Total RAM: $totalRam GB*"">"
Write-Host "<WRITE-LOG = ""*Filesystem Usage:*"">"

foreach ($drive in $filesystemUsage) {
    Write-Host "<WRITE-LOG = ""*Drive: $($drive.Name), Usage: $($drive.'Usage(%)')%, Used: $($drive.'Used(GB)') GB, Total: $($drive.'Total(GB)') GB*"">"
}

