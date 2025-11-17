<# Install the Application Compatibility Feature on Demand on Server Core
 
Component                       Filename 	    
Device Manager                  devmgmt.msc 	
Disk Management                 diskmgmt.msc 	
Event Viewer                    eventvwr.msc 	
Failover Cluster Manager        cluadmin.msc 	
File Explorer                   explorer.exe 	
Hyper-V Manager                 virtmgmt.msc 	
Microsoft Management Console    mmc.exe 	        
Performance Monitor             perfmon.exe 	    
Resource Monitor                resmon.exe 	        
Task Scheduler                  taskschd.msc 	    
Windows PowerShell (ISE)        powershell_ise.exe 	

#>

Add-WindowsCapability -Online -Name "ServerCore.AppCompatibility~~~~0.0.1.0"

# Reboot after installation has completed!