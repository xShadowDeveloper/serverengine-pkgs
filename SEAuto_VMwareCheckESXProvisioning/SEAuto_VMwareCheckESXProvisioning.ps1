<#
.SYNOPSIS
VMware ESXi or vCenter Provisioning Checker
.DESCRIPTION
This PowerCLI script connects to a VMware ESXi host or vCenter server and provides a 
detailed overview of resource allocation for the host and its virtual machines. 
It collects information on physical host resources, including total CPU cores, threads, 
and memory, as well as assigned resources for all powered-on VMs. 
The script calculates available and free resources, highlights potential overprovisioning 
of CPU or RAM, and outputs a clear summary for both the host and each VM. 
It is designed to help administrators quickly assess host capacity, VM assignments, 
and resource provisioning to ensure optimal performance and avoid overcommitment.
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
# ===============================================
# PowerCLI Script: Host + VM Assigned Resources
# ===============================================

# Connect to ESXi or vCenter
$server   = "YOURESXiHOST"
$user     = "root"
$password = "YOURHOSTpassword"

Connect-VIServer -Server $server -User $user -Password $password

# Get the host object
$esx = Get-VMHost
$esxView = Get-View $esx.ID

# --------------------
# Host physical resources
# --------------------
$cpuCores        = $esxView.Hardware.CpuInfo.NumCpuCores
$cpuThreads      = $esxView.Hardware.CpuInfo.NumCpuThreads
$memTotalGB = [math]::Round($esx.MemoryTotalMB / 1024, 1)

# --------------------
# VM assigned resources
# --------------------
$vms = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}
$totalCpuAssigned = ($vms | Measure-Object -Property NumCpu -Sum).Sum
$totalMemAssigned = ($vms | Measure-Object -Property MemoryGB -Sum).Sum

# --------------------
# Free resources (can be negative for CPU overcommit)
# --------------------
$cpuFree = $cpuThreads - $totalCpuAssigned
$memFree = $memTotalGB - $totalMemAssigned

# Check Provisioning
$cpuProvisioning = "OK"
$ramProvisioning = "OK"

if($totalCpuAssigned -gt $cpuThreads){
    $cpuProvisioning = "Overprovisioned"
    #Write-Error "CPU State: $cpuProvisioning"
}
if($totalMemAssigned -gt $memTotalGB){
    $ramProvisioning = "Overprovisioned"
    #Write-Error "RAM State: $cpuProvisioning"
}
# --------------------
# Output Host Summary
# --------------------
Write-Host ""
Write-Host "<WRITE-LOG = ""*================== Host Resource Summary ==================*"">"
Write-Host "<WRITE-LOG = ""*Host: $($esx.Name)*"">"
Write-Host "<WRITE-LOG = ""*CPU: State: $($cpuProvisioning.PadRight(15)) *"">"
Write-Host "<WRITE-LOG = ""*RAM: State: $($ramProvisioning.PadRight(15)) *"">"
Write-Host "<WRITE-LOG = ""*Available:[$($cpuThreads.ToString().PadLeft(3)) vCPUs ] Assigned:[$($totalCpuAssigned.ToString().PadLeft(3)) vCPUs ] Free:[$($cpuFree.ToString().PadLeft(3)) vCPUs ]*"">"
Write-Host "<WRITE-LOG = ""*Available:[$($memTotalGB.ToString().PadLeft(6)) GB ] Assigned:[$($totalMemAssigned.ToString().PadLeft(6)) GB ] Free:[$($memFree.ToString().PadLeft(6)) GB ]*"">"

# --------------------
# Per-VM Assigned Resources
# --------------------
Write-Host "<WRITE-LOG = ""*================== VM Assigned Resources ==================*"">"
$vms | ForEach-Object {
    Write-Host "<WRITE-LOG = ""*vCPUs: [$($_.NumCpu.ToString().PadLeft(2)) ] RAM: [$($_.MemoryGB.ToString().PadLeft(3)) GB ] VM: $($_.Name)*"">"
}
# --------------------
# Disconnect
# --------------------
Disconnect-VIServer -Server $server -Confirm:$false
