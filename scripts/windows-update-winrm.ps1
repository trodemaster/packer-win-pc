# Powershell version of install windows update via task scheduler
# This script creates a logon task to run windows updates.
# Depends on packer windows-restart to start the taks and stop winrm. 
# After all updaets are instaled winrm is started and the login task is removed. 

# setup window name and script name variable
$scriptname="windows-update-winrm.ps1"
$host.ui.RawUI.WindowTitle = "$scriptname"

# start logging
start-transcript -path c:\windows\temp\windows-update-winrm.log -append

# Report the IE version Installed
Write-output ("Installed IE Version currently is " + (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Internet Explorer').Version)

# Report the powershell version installed
$powershellversion=$PSVersionTable.PSVersion
write-output "Powershell version $powershellversion installed"
if ($PSVersionTable.PSVersion.Major -lt 5) {
    write-output "Powershell upgrade in previous step failed!!"
    get-content "C:\Windows\wsusofflineupdate.log"
    exit 1
}

# Report the version of windows update agent
$wu_agent=(get-command C:\windows\system32\wups2.dll).version
if ($wu_agent -ge [Version]"7.6.7601.19161") {
  write-output "Windows Update agent is current! $wu_agent"
} else {
  write-output "Windows Update agent out of date! $wu_agent"
}

# Check to see if scheduled task called $scriptname exists
if (schtasks /query /tn $scriptname 2>$null ) {
  write-output "Checking for updates...."
  Get-WUInstallerStatus
    # hack to get buggy windows 7 to show updates
    #if ([Environment]::OSVersion.Version -le [Version]"6.1.7601.65536") {
      #if ((gwmi win32_operatingsystem).OperatingSystemSKU -notmatch "(\b[7-9]|10|1[2-5]|1[7-9]|2[0-5])") { 
        if ([Version](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Internet Explorer').Version -le [Version]"9.11.9600.18231") {
          write-output "Forcing Windows to search for updates until it finds some...."
          while (-not(Get-WindowsUpdate -notCategory "Windows 7 Language Packs")) {
            write-output "Still looking for updates...."
          }
          Write-output "Win Found some updates" 
        }
      #}
    #}
  # Actually install the updates starts here.. 
  if (Get-WindowsUpdate -notCategory "Windows 7 Language Packs" -NotTitle "Printer")
  {
    write-output "Starting Windows update installation..."
    # run windows updates
    Install-WindowsUpdate -IgnoreUserInput -AcceptALL -IgnoreReboot -verbose -notCategory "Windows 7 Language Packs" 
    # restart after every insstall of updates
    stop-transcript
    restart-computer
  } else {
    write-output "No updates found..."
    # maybe check for systems that still show zero installed updates and reboot
    #if (Get-WUList -IsInstalled) {write-output "updates have been installed"}
    #remove scheduled task
    schtasks /delete /tn $scriptname /f
    # stop logging & dump to console so it gets recorded in packer log
    #get-content c:\windows\temp\windows-update-winrm.log
    # start winrm service and set to autostart
    start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "config WinRM start= delayed-auto" -wait
    #start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "start WinRM" -wait
    stop-transcript
    restart-computer
  }
} else {
    # first run of script
    # setup windows updater components
    $ErrorActionPreference = 'Stop'
    # install nuget
    write-output "Installing NuGet"
    
    [int]$attempts = 0
    do {
        try {
            $attempts +=1
            Get-PackageProvider -Name NuGet -ForceBootstrap
            if (-not([string](Get-PackageProvider).name -match "NuGet")) { throw "Error installing NuGet" }
            break
        } catch {
            write-host "Problem installing NuGet `tAttempt $attempts `
                       `n`tException: " $_.Exception.Message
            start-sleep -s 20
        }
    }
    while ($attempts -lt 10)
    if ($attempts -ge 10) {
        write-host "NuGet failed to install!!"
        exit 1
    }
    
    # allow repo install
    write-output "adding PSGallery repo"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    
    # install PSWindowsUpdate
    write-output "Installing PSWindowsUpdate"
    Install-Module -Name PSWindowsUpdate -Confirm:$false | out-null
    write-output "Installed PSWindowsUpdate"

    # attempt install early for debugging
    #Get-WUInstallerStatus

    #Get-WindowsUpdate -notCategory "Windows 7 Language Packs"
    write-output "Modern windows update tools installed..."
    
    ##### Debugging BS for windows 7 below..
    #start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "config bits start= auto" -wait
    #start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "config wuauserv start= auto" -wait
    #start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "config appidsvc start= auto" -wait
    #start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "config cryptsvc start= auto" -wait

    #if ([Environment]::OSVersion.Version -le [Version]"6.2") {
    #  Write-output "Installing KB KB2966583"
    #  Install-WindowsUpdate -KBArticleID KB2966583 -acceptall 
    #}

    # Stops the windows update service.  
    # Get-Service -Name wuauserv | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue 
     
    # Delete the contents of windows software distribution.
    #write-output "Delete the contents of windows software distribution"
    #Get-ChildItem "C:\Windows\SoftwareDistribution\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | remove-item -force -recurse -ErrorAction SilentlyContinue 
    
    # setup windows update server from envrionment variables
    #write-output "Windows Update Group $env:wsus_group"
    #write-output "Windows Update Server $env:wsus_server"
    # check if you can reach the wsus server
    #If (test-connection -quiet $env:wsus_server) {
    #$wsusserver="http://" + $env:wsus_server + ":8530"
    #} elseif (test-connection -quiet 10.122.168.21) {
    #$wsusserver="http://10.122.168.21:8530"
    #} else {
    #write-output "Unable to contact the wsus server. Using microsoft.com"
    #}
    # set windows updates to pull from local wsus server
    #if ($wsusserver) {
    #write-output "WSUS server contacted " $wsusserver
    #New-Item -Path "HKLM:Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -force -ErrorAction SilentlyContinue
    #Set-ItemProperty -Path "HKLM:\software\policies\Microsoft\Windows\WindowsUpdate" -Name WUServer -Value $wsusserver -Type String -force
    #Set-ItemProperty -Path "HKLM:\software\policies\Microsoft\Windows\WindowsUpdate" -Name WUStatusServer -Value $wsusserver -Type String -force
    #Set-ItemProperty -Path "HKLM:\software\policies\Microsoft\Windows\WindowsUpdate\AU" -Name UseWUServer -Value "1" -Type DWORD -force
    #Set-ItemProperty -Path "HKLM:\software\policies\Microsoft\Windows\WindowsUpdate" -Name TargetGroupEnabled -Value "1" -Type DWORD -force
    #Set-ItemProperty -Path "HKLM:\software\policies\Microsoft\Windows\WindowsUpdate" -Name TargetGroup -Value $env:wsus_group -Type String -force
    #}
    # set winrm to manual start to prevent packer from connecting on reboot
    Set-Service -Name winrm -StartupType Manual
    # if schedled task does not exist create it
    Write-output "Creating scheduled task to start $scriptname with proper elevation"
    # setup task scheduler login item to process this script next boot
    schtasks /create /ru "BUILTIN\administrators" /sc ONLOGON /tn $scriptname /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File C:\windows\temp\$scriptname" /rl highest /f /np
 }
stop-transcript
exit 0