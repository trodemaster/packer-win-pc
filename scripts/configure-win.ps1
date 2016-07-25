# windows server cleanup

# test to see if this is a desktop version of windows
$windesktop = (gwmi win32_operatingsystem).OperatingSystemSKU -notmatch "(\b[7-9]|10|1[2-5]|1[7-9]|2[0-5])"                           
if ($windesktop) 
{ 
    write-output "This is a desktop version of windows" 
} 

write-output "Disable Hybernation"
powercfg -hibernate OFF

write-output  "configure screen saver"
Set-ItemProperty -Path "registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name ScreenSaveActive -Value 0

write-output  "change administrator user pass next login"
# this gets reset by sysprep/guest customization. need to set it again in the guest customization script. 
net user localuser /logonpasswordchg:no

write-output  "Enable administrator account"
net user administrator /active:yes

write-output  "Disable firewall"
netsh advfirewall set allprofiles state off

write-output  "supress network location Prompt"
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force

# remove troublesome 3rd party app store apps that cause sysprep to fail
if ($windesktop) 
{ 
 if ([Environment]::OSVersion.Version -ge (new-object 'Version' 10,0))
  {
    Get-AppxPackage -user localuser PackageFullName | Remove-AppxPackage -ErrorAction SilentlyContinue
  }  
}

## Optimize IPv6 settings
write-output  "disable privacy IPv6 addresses"
netsh interface ipv6 set privacy state=disabled store=active
netsh interface ipv6 set privacy state=disabled store=persistent

write-output  "enable EUI-64 addressing"
netsh interface ipv6 set global randomizeidentifiers=disabled store=active
netsh interface ipv6 set global randomizeidentifiers=disabled store=persistent

write-output  "Enable Remote Desktop"
(Get-WmiObject Win32_TerminalServiceSetting -Namespace root\cimv2\TerminalServices).SetAllowTsConnections(1,1) | Out-Null
(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\TerminalServices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0) | Out-Null

write-output  "Clear windows autologon"
Remove-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultDomainName -EA 0
Remove-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -EA 0
Remove-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -EA 0
Remove-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserPassword -EA 0

# not the most secure option here.. 
write-output  "Enable remote command policy"
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name LocalAccountTokenFilterPolicy -Value 1 -Type DWord

# sysprep with wmf 5 fix
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\StreamProvider -Name LastFullPayloadTime -Value 0 -Type DWord

# set ntp to sync time before domain join
Write-Output "Setting System Time Zone to UTC `r"
tzutil.exe /s "UTC"

write-output  "setup guest customization shim"
if(!(Test-Path -Path "C:\Windows\Setup\Scripts" )){
    New-Item -ItemType directory -Path "C:\Windows\Setup\Scripts"
}
Set-Content -path C:\windows\setup\scripts\SetupComplete.cmd -value 'powershell -executionpolicy bypass -file C:\windows\setup\scripts\SetupComplete.ps1' 
move-item c:\windows\temp\SetupComplete.ps1 c:\windows\setup\scripts\

