<#
.SYNOPSIS
Install and configure UltraVNC Server for ServerEngine Management
.DESCRIPTION
This PowerShell script automatically checks for and installs UltraVNC Server if missing, 
performing a silent installation with pre-configured security settings, MS Logon authentication, 
and a firewall rule.
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

# Check if installed
$uvncInstalled = Get-Package -Name "*ultravnc*" -ErrorAction SilentlyContinue 2>$null
if(-not $uvncInstalled){

Write-Host "<WRITE-LOG = ""*Installing UVNC Server...*"">"

# ===== CONFIGURATION =====
$DownloadURL = "https://uvnc.eu/download/1640/UltraVNC_1640_x64_Setup.exe"
$InstallerPath = "$env:TEMP\UltraVNC_1640_x64_Setup.exe"

$ConfigContent = @"
[ultravnc]
passwd=FB0B44D3653641D2CB
passwd2=FB0B44D3653641D2CB
[admin]
AllowUserSettingsWithPassword=0
FileTransferEnabled=1
FTUserImpersonation=0
BlankMonitorEnabled=1
BlankInputsOnly=0
DefaultScale=1
UseDSMPlugin=1
DSMPlugin=SecureVNCPlugin64.dsm
DSMPluginConfig=SecureVNC;0;0x00104001;
AuthHosts=
primary=1
secondary=0
SocketConnect=1
HTTPConnect=0
AutoPortSelect=0
PortNumber=5900
HTTPPortNumber=5800
InputsEnabled=1
LocalInputsDisabled=0
IdleTimeout=0
EnableJapInput=0
EnableUnicodeInput=1
EnableWin8Helper=0
QuerySetting=2
QueryTimeout=10
QueryDisableTime=1
QueryAccept=0
MaxViewerSetting=0
MaxViewers=128
Collabo=0
Frame=1
Notification=0
OSD=0
NotificationSelection=0
QueryIfNoLogon=1
LockSetting=0
RemoveWallpaper=1
RemoveEffects=0
RemoveFontSmoothing=0
DebugMode=0
Avilog=0
path=C:\Program Files\uvnc bvba\UltraVNC
DebugLevel=0
AllowLoopback=1
UseIpv6=0
LoopbackOnly=0
AllowShutdown=1
AllowProperties=1
AllowInjection=0
AllowEditClients=1
FileTransferTimeout=30
KeepAliveInterval=5
IdleInputTimeout=0
DisableTrayIcon=0
rdpmode=1
noscreensaver=0
Secure=1
MSLogonRequired=1
NewMSLogon=1
ReverseAuthRequired=1
ConnectPriority=1
AuthRequired=1
service_commandline=
accept_reject_mesg=Allow access to your computer?
cloudServer=
cloudEnabled=0
[poll]
TurboMode=1
PollUnderCursor=0
PollForeground=0
PollFullScreen=1
OnlyPollConsole=0
OnlyPollOnEvent=0
MaxCpu2=100
MaxFPS=25
EnableDriver=1
EnableHook=1
EnableVirtual=0
autocapt=1
[admin_auth]
group1=
group2=
group3=
locdom1=0
locdom2=0
locdom3=0
"@
$ACL = @'
allow 0x3 "..\Domain Admins"
'@

# ===== INSTALLATION =====
# 1. Download installer
Invoke-WebRequest -Uri $DownloadURL -OutFile $InstallerPath

# 2. Silent install (Service + Viewer)
Start-Process -FilePath "$env:TEMP\.\UltraVNC_1640_x64_Setup.exe" -ArgumentList "/VERYSILENT /NORESTART /Type=custom /Components=ultravnc_server /Tasks=installservice,startservice " -Wait

New-Item -Path "$env:ProgramData\UltraVNC" -ItemType Directory -Force

# 4. Deploy ultravnc.ini
$ConfigContent | Out-File -FilePath "$env:ProgramData\UltraVNC\ultravnc.ini" -Encoding ASCII -Force

# 5. Allow Grousp NEW-MsLogon
$ACL | Out-File -FilePath "$env:ProgramData\UltraVNC\allow_groups.acl" -Encoding ASCII -Force 2>&1
& "C:\Program Files\uvnc bvba\UltraVNC\MSLogonACL.exe" /i /o $env:ProgramData\UltraVNC\allow_groups.acl *>$null

# 6. Set firewall rule
if (!(Get-NetFirewallRule -DisplayName "UltraVNC" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "UltraVNC" -Direction Inbound -LocalPort 5900 -Protocol TCP -Action Allow
    Write-Host "Firewall rule created successfully"
} else {
    Write-Host "Firewall rule already exists"
}

# ===== VERIFICATION =====
Write-Host "UltraVNC installed to: $InstallDir"
Write-Host "Config file deployed to: $env:ProgramData\UltraVNC\ultravnc.ini"

# Path to winvnc.exe
$winvnc = "C:\Program Files\uvnc bvba\UltraVNC\winvnc.exe"

Start-Process $winvnc
Write-Host "<WRITE-LOG = ""*UVNC Server installation completed successfully.*"">"


}else{
	if (Test-Path "C:\Program Files\uvnc bvba\UltraVNC\winvnc.exe") {
        Write-Host "<WRITE-LOG = ""*UVNC Server is already installed.*"">"
	}

}

