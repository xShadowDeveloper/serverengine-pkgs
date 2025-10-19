# ===============================================
# PowerCLI Script: Host + VM Assigned Resources
# ===============================================

# Connect to ESXi or vCenter
$server   = "esxi.cforce-it.network"
$user     = "root"
$password = "AdminZeus.21"

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
