<#
.SYNOPSIS
Handles system reboot for ServerEngine managed reboot cycles   
.DESCRIPTION
This script initiates a system restart and reports reboot state to ServerEngine.
Include in deployment packages when ServerEngine should manage reboot cycles seamlessly.
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

Invoke-Command { Start-Sleep 3;Write-Host " ""State : Reboot"" ";Restart-Computer -Force }; Exit-PSSession 
