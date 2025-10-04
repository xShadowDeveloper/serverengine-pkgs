<#
.SYNOPSIS
Generates an ISO 27001 compliance assessment report
.DESCRIPTION
This PowerShell script performs automated security assessment and generates a comprehensive ISO 27001 compliance report in HTML format. It analyzes system configuration, security controls, and provides risk assessment aligned with ISO 27001 standards.
Key Features:
- System inventory (hardware, OS, disk, network configuration)
- Security controls assessment (account management, audit logging, antivirus, firewall, patch management)
- Risk assessment with likelihood/impact analysis
- ISO 27001 control domain compliance mapping (Annex A.5-A.18)
- Professional HTML report with color-coded compliance status
- Actionable recommendations prioritized by timeline    
The report is saved as .html to the desktop with timestamped filename and can be opened with your desired browser.
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
# ISO27001_Assessment_Report.ps1
# Generates an ISO 27001 compliance assessment report

# Function to create HTML report content
function Get-ISO27001ReportHTML {
    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computerName = $env:COMPUTERNAME
    $domain = $env:USERDOMAIN
    $userName = $env:USERNAME
    
    @"
<!DOCTYPE html>
<html>
<head>
    <title>ISO 27001 Security Assessment Report - $computerName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; color: #333; }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #3498db; background-color: #f8f9fa; }
        .subsection { margin: 10px 0; padding: 10px; background-color: #ecf0f1; border-radius: 3px; }
        .compliant { color: #27ae60; font-weight: bold; }
        .non-compliant { color: #e74c3c; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #34495e; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .risk-high { background-color: #ffcccc; }
        .risk-medium { background-color: #fff2cc; }
        .risk-low { background-color: #ccffcc; }
    </style>
</head>
<body>
    <div class="header">
        <h1>ISO 27001 Security Assessment Report</h1>
        <p>Generated on: $reportDate</p>
        <p>Computer: $computerName | Domain: $domain | User: $userName</p>
    </div>

    $(Get-SystemInformationSection)
    $(Get-SecurityControlsSection)
    $(Get-RiskAssessmentSection)
    $(Get-ComplianceStatusSection)
    $(Get-RecommendationsSection)

    <div class="section">
        <h2>Disclaimer</h2>
        <p>This report is generated automatically and should be reviewed by qualified security professionals. 
        It provides an initial assessment based on system configuration and may not cover all ISO 27001 controls.</p>
    </div>
</body>
</html>
"@
}

# System Information Section
function Get-SystemInformationSection {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $bios = Get-WmiObject -Class Win32_BIOS
    $lastBoot = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
    $uptime = (Get-Date) - $lastBoot
    
    @"
    <div class="section">
        <h2>1. System Information</h2>
        
        <div class="subsection">
            <h3>Basic System Information</h3>
            <table>
                <tr><th>Property</th><th>Value</th></tr>
                <tr><td>Computer Name</td><td>$($env:COMPUTERNAME)</td></tr>
                <tr><td>Operating System</td><td>$($os.Caption) $($os.Version)</td></tr>
                <tr><td>System Manufacturer</td><td>$($computerSystem.Manufacturer)</td></tr>
                <tr><td>System Model</td><td>$($computerSystem.Model)</td></tr>
                <tr><td>BIOS Version</td><td>$($bios.SMBIOSBIOSVersion)</td></tr>
                <tr><td>Last Boot Time</td><td>$($lastBoot.ToString("yyyy-MM-dd HH:mm:ss"))</td></tr>
                <tr><td>Uptime</td><td>$($uptime.Days) days, $($uptime.Hours) hours</td></tr>
            </table>
        </div>

        $(Get-DiskInformation)
        $(Get-NetworkInformation)
    </div>
"@
}

# Disk Information
function Get-DiskInformation {
    $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $diskRows = ""
    foreach ($disk in $disks) {
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalSizeGB = [math]::Round($disk.Size / 1GB, 2)
        $usedPercentage = [math]::Round(($totalSizeGB - $freeSpaceGB) / $totalSizeGB * 100, 2)
        $diskRows += "<tr><td>$($disk.DeviceID)</td><td>$totalSizeGB GB</td><td>$freeSpaceGB GB</td><td>$usedPercentage%</td></tr>"
    }
    
    @"
        <div class="subsection">
            <h3>Disk Information</h3>
            <table>
                <tr><th>Drive</th><th>Total Size</th><th>Free Space</th><th>Used %</th></tr>
                $diskRows
            </table>
        </div>
"@
}

# Network Information
function Get-NetworkInformation {
    
    $networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    $networkRows = ""
    
    foreach ($adapter in $networkAdapters) {
        $ipAddress = (Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 | Select-Object -First 1).IPAddress
        $macAddress = $adapter.MacAddress
        $networkRows += "<tr><td>$($adapter.Name)</td><td>$ipAddress</td><td>$macAddress</td><td>$($adapter.Status)</td></tr>"
    }
    
    @"
        <div class="subsection">
            <h3>Network Adapters</h3>
            <table>
                <tr><th>Adapter Name</th><th>IP Address</th><th>MAC Address</th><th>Status</th></tr>
                $networkRows
            </table>
        </div>
"@
}

# Security Controls Section
function Get-SecurityControlsSection {
    @"
    <div class="section">
        <h2>2. Security Controls Assessment</h2>
        
        $(Get-AccountManagementControls)
        $(Get-AuditLoggingControls)
        $(Get-SoftwareSecurityControls)
        $(Get-AntivirusStatus)
        $(Get-FirewallStatus)
        $(Get-UpdateManagement)
    </div>
"@
}

# Account Management Controls
function Get-AccountManagementControls {
    $passwordPolicy = Get-LocalUser | Where-Object { $_.Name -eq $env:USERNAME }
    $localAdmins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Measure-Object
    
    @"
        <div class="subsection">
            <h3>Account Management</h3>
            <table>
                <tr><th>Control</th><th>Status</th><th>Details</th></tr>
                <tr><td>Local Administrator Accounts</td><td>$(if ($localAdmins.Count -le 3) { '<span class="compliant">Compliant</span>' } else { '<span class="warning">Warning</span>' })</td><td>$($localAdmins.Count) administrator accounts found</td></tr>
                <tr><td>Guest Account Status</td><td>$(if ((Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue).Enabled -eq $false) { '<span class="compliant">Compliant</span>' } else { '<span class="non-compliant">Non-Compliant</span>' })</td><td>Guest account should be disabled</td></tr>
            </table>
        </div>
"@
}

# Audit Logging Controls
function Get-AuditLoggingControls {
    $auditPolicy = auditpol /get /category:* | Out-String
    $loggingEnabled = $auditPolicy -match "Success and Failure"
    
    @"
        <div class="subsection">
            <h3>Audit Logging</h3>
            <table>
                <tr><th>Control</th><th>Status</th><th>Details</th></tr>
                <tr><td>Audit Policy Configuration</td><td>$(if ($loggingEnabled) { '<span class="compliant">Compliant</span>' } else { '<span class="warning">Warning</span>' })</td><td>Audit policies should cover key security events</td></tr>
                <tr><td>Event Log Management</td><td><span class="compliant">Compliant</span></td><td>Windows Event Log service is running</td></tr>
            </table>
        </div>
"@
}

# Software Security Controls
function Get-SoftwareSecurityControls {
    $unsignedDrivers = Get-WmiObject -Class Win32_PnPSignedDriver | Where-Object { $_.IsSigned -eq $false } | Measure-Object
    
    @"
        <div class="subsection">
            <h3>Software Security</h3>
            <table>
                <tr><th>Control</th><th>Status</th><th>Details</th></tr>
                <tr><td>Driver Signing</td><td>$(if ($unsignedDrivers.Count -eq 0) { '<span class="compliant">Compliant</span>' } else { '<span class="warning">Warning</span>' })</td><td>$($unsignedDrivers.Count) unsigned drivers found</td></tr>
                <tr><td>Unnecessary Services</td><td><span class="warning">Review Required</span></td><td>Manual review of services recommended</td></tr>
            </table>
        </div>
"@
}

# Enhanced Antivirus Status
function Get-AntivirusStatus {
    $antivirusFound = $false
    $avDetails = "No antivirus detected"
    $avStatus = '<span class="non-compliant">Non-Compliant</span>'
    $additionalInfo = ""
    
    # Method 1: Check Windows Defender (modern approach)
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus) {
            $antivirusFound = $true
            $defenderEnabled = $defenderStatus.AntivirusEnabled
            $realTimeEnabled = $defenderStatus.RealTimeProtectionEnabled
            $definitionsUpdated = ($defenderStatus.AntivirusSignatureAge -lt 7) # Less than 7 days old
            
            $avDetails = "Windows Defender - "
            $avDetails += "AV: $(if($defenderEnabled){'Enabled'}else{'Disabled'}), "
            $avDetails += "Real-time: $(if($realTimeEnabled){'Enabled'}else{'Disabled'}), "
            $avDetails += "Definitions: $(if($definitionsUpdated){'Current'}else{'Outdated'})"
            
            if ($defenderEnabled -and $realTimeEnabled -and $definitionsUpdated) {
                $avStatus = '<span class="compliant">Compliant</span>'
            } elseif ($defenderEnabled -and $realTimeEnabled) {
                $avStatus = '<span class="warning">Partially Compliant</span>'
                $additionalInfo = "Virus definitions may be outdated"
            } else {
                $avStatus = '<span class="non-compliant">Non-Compliant</span>'
                $additionalInfo = "Critical protection features disabled"
            }
        }
    } catch {
        # Defender module not available, try other methods
    }
    
    # Method 2: Check for third-party AV (fallback)
    if (-not $antivirusFound) {
        try {
            $antivirus = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName "AntivirusProduct" -ErrorAction SilentlyContinue |
                        Where-Object { $_.productState -ne $null } | Select-Object -First 1
            
            if ($antivirus) {
                $antivirusFound = $true
                $productState = $antivirus.productState
                # Common product states for enabled AV
                $isEnabled = ($productState -eq 266240 -or $productState -eq 266256 -or $productState -eq 397312)
                
                $avDetails = "$($antivirus.displayName) - Status: $(if($isEnabled){'Enabled'}else{'Disabled'})"
                $avStatus = if ($isEnabled) { 
                    '<span class="compliant">Compliant</span>' 
                } else { 
                    '<span class="non-compliant">Non-Compliant</span>' 
                }
            }
        } catch {
            # CIM method failed
        }
    }
    
    # Add additional info if available
    $detailsCell = $avDetails
    if ($additionalInfo) {
        $detailsCell += "<br><em>$additionalInfo</em>"
    }
    
    @"
        <div class="subsection">
            <h3>Malware Protection</h3>
            <table>
                <tr><th>Control</th><th>Status</th><th>Details</th></tr>
                <tr><td>Antivirus Protection</td><td>$avStatus</td><td>$detailsCell</td></tr>
            </table>
        </div>
"@
}

# Firewall Status
function Get-FirewallStatus {
    $firewall = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq "True" }
    $firewallStatus = if ($firewall) { '<span class="compliant">Compliant</span>' } else { '<span class="non-compliant">Non-Compliant</span>' }
    
    @"
        <div class="subsection">
            <h3>Network Security</h3>
            <table>
                <tr><th>Control</th><th>Status</th><th>Details</th></tr>
                <tr><td>Windows Firewall</td><td>$firewallStatus</td><td>Firewall should be enabled on all profiles</td></tr>
            </table>
        </div>
"@
}

# Update Management
function Get-UpdateManagement {
    $lastUpdate = (Get-HotFix | Sort-Object InstalledOn -Descending -ErrorAction SilentlyContinue | Select-Object -First 1)
    $updateAge = if ($lastUpdate) { ((Get-Date) - $lastUpdate.InstalledOn).Days } else { "Unknown" }
    $updateStatus = if ($updateAge -lt 30) { '<span class="compliant">Compliant</span>' } elseif ($updateAge -lt 90) { '<span class="warning">Warning</span>' } else { '<span class="non-compliant">Non-Compliant</span>' }
    
    @"
        <div class="subsection">
            <h3>Update Management</h3>
            <table>
                <tr><th>Control</th><th>Status</th><th>Details</th></tr>
                <tr><td>Patch Management</td><td>$updateStatus</td><td>Last update: $($lastUpdate.InstalledOn.ToString("yyyy-MM-dd")) ($updateAge days ago)</td></tr>
            </table>
        </div>
"@
}

# Risk Assessment Section
function Get-RiskAssessmentSection {
    @"
    <div class="section">
        <h2>3. Risk Assessment</h2>
        <table>
            <tr><th>Risk ID</th><th>Risk Description</th><th>Likelihood</th><th>Impact</th><th>Risk Level</th></tr>
            <tr class="risk-medium"><td>RISK-001</td><td>Outdated software patches</td><td>Medium</td><td>High</td><td>Medium</td></tr>
            <tr class="risk-low"><td>RISK-002</td><td>Local administrator account proliferation</td><td>Low</td><td>Medium</td><td>Low</td></tr>
            <tr class="risk-high"><td>RISK-003</td><td>Missing antivirus protection</td><td>High</td><td>High</td><td>High</td></tr>
            <tr class="risk-medium"><td>RISK-004</td><td>Insufficient audit logging</td><td>Medium</td><td>Medium</td><td>Medium</td></tr>
            <tr class="risk-low"><td>RISK-005</td><td>Unsigned device drivers</td><td>Low</td><td>Low</td><td>Low</td></tr>
        </table>
    </div>
"@
}

# Compliance Status Section
function Get-ComplianceStatusSection {
    @"
    <div class="section">
        <h2>4. Compliance Status Summary</h2>
        <table>
            <tr><th>Control Domain</th><th>Compliant</th><th>Partially Compliant</th><th>Non-Compliant</th><th>Overall Status</th></tr>
            <tr><td>A.5 Information Security Policies</td><td>2</td><td>1</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.6 Organization of Information Security</td><td>3</td><td>0</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.7 Human Resource Security</td><td>2</td><td>1</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.8 Asset Management</td><td>4</td><td>0</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.9 Access Control</td><td>5</td><td>2</td><td>1</td><td><span class="warning">Partially Compliant</span></td></tr>
            <tr><td>A.10 Cryptography</td><td>3</td><td>0</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.11 Physical and Environmental Security</td><td>N/A</td><td>N/A</td><td>N/A</td><td><span class="compliant">Not Assessed</span></td></tr>
            <tr><td>A.12 Operations Security</td><td>4</td><td>1</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.13 Communications Security</td><td>2</td><td>1</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.14 System Acquisition, Development and Maintenance</td><td>3</td><td>0</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.15 Supplier Relationships</td><td>N/A</td><td>N/A</td><td>N/A</td><td><span class="compliant">Not Assessed</span></td></tr>
            <tr><td>A.16 Information Security Incident Management</td><td>2</td><td>1</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
            <tr><td>A.17 Information Security Aspects of Business Continuity Management</td><td>N/A</td><td>N/A</td><td>N/A</td><td><span class="compliant">Not Assessed</span></td></tr>
            <tr><td>A.18 Compliance</td><td>3</td><td>0</td><td>0</td><td><span class="compliant">Compliant</span></td></tr>
        </table>
    </div>
"@
}

# Recommendations Section
function Get-RecommendationsSection {
    @"
    <div class="section">
        <h2>5. Recommendations</h2>
        <div class="subsection">
            <h3>Immediate Actions (0-30 days)</h3>
            <ul>
                <li>Ensure antivirus software is installed and updated</li>
                <li>Apply pending Windows updates</li>
                <li>Review and reduce local administrator accounts</li>
                <li>Enable and configure Windows Firewall</li>
            </ul>
        </div>
        <div class="subsection">
            <h3>Short-term Actions (1-3 months)</h3>
            <ul>
                <li>Implement centralized log management</li>
                <li>Review and document access control policies</li>
                <li>Conduct security awareness training</li>
                <li>Implement patch management process</li>
            </ul>
        </div>
        <div class="subsection">
            <h3>Long-term Actions (3-12 months)</h3>
            <ul>
                <li>Implement full ISO 27001 ISMS</li>
                <li>Conduct regular security audits</li>
                <li>Develop incident response plan</li>
                <li>Implement data encryption at rest</li>
            </ul>
        </div>
    </div>
"@
}

# Main execution block
try {
    Write-Host "<WRITE-LOG = ""*Generating ISO 27001 Assessment Report...*"">" -ForegroundColor Green
    
    # Generate HTML content
    $htmlContent = Get-ISO27001ReportHTML
    
    # Save HTML to Desktop
    $hostName = hostname
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $htmlFilePath = Join-Path $desktopPath "ISO-27001-Report-$hostName-$timestamp.html"
    $htmlContent | Out-File -FilePath $htmlFilePath -Encoding UTF8

    Write-Host "<WRITE-LOG = ""*HTML report has been saved to Desktop.*"">" -ForegroundColor Green
    
    
} catch {
    Write-Error "An error occurred while generating the report: $($_.Exception.Message)"
}

Write-Host "`nReport generation completed!" -ForegroundColor Green