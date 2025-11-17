<#
.SYNOPSIS
Auto Disk Health & Cleanup
.DESCRIPTION
Checks for low disk space and performs cleanup (temp, recycle bin, update cache).
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

$Threshold = 50  # Disk usage % limit
$Drives = Get-PSDrive -PSProvider 'FileSystem'

foreach ($Drive in $Drives) {
    try {
        $Usage = [math]::Round((($Drive.Used / ($Drive.Free + $Drive.Used)) * 100), 2)
        Write-Host "<WRITE-LOG = ""*Checking $($Drive.Name): $Usage% used*"">"

        if ($Usage -ge $Threshold) {
            Write-Host "<WRITE-LOG = ""*Drive $($Drive.Name) exceeds threshold ($Usage%) - cleaning...*"">"
            
            # Clear temp files
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

            # Empty recycle bin
            (New-Object -ComObject Shell.Application).NameSpace(0xA).Items() | 
                ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }

            # Clear Windows Update cache
            Stop-Service wuauserv -ErrorAction SilentlyContinue
            Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service wuauserv -ErrorAction SilentlyContinue
            
            Write-Host "<WRITE-LOG = ""*Cleanup completed for $($Drive.Name)*"">"
        }
    } catch {
        Write-Host "Error processing $($Drive.Name): $_"
    }
}
