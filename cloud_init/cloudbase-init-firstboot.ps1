#ps1_sysnative
# powershell guest customizatin payload script for vcloud and vsphere

write-output "itc customization started"

# setup logging
Start-Transcript -path c:\windows\temp\cloudbase-init-firstboot.log -Append -force


## Identify the version of windows

# test to see if this is a desktop version of windows
$windesktop = (gwmi win32_operatingsystem).OperatingSystemSKU -notmatch "(\b[7-9]|10|1[2-5]|1[7-9]|2[0-5])"                           
if ($windesktop) 
{ 
    write-output "This is a desktop version of windows" 
}

# get the windows kernel version
$KERNELVERSION = [Environment]::OSVersion.Version

# example test for reference.
# 6.1 = Windows 7 & 2008 R2
# 6.2 = Windows 8 & Server 2012
# 6.3 = Windows 8.1 & Server 2012 R2
# 10.0 = Windows 10 & Server 2016
if ($KERNELVERSION -ge (new-object 'Version' 10,0)) {
  write-output "Windows 10 kernel version"
} 

## Set windows computer/hostname from the primary IP reverse DNS record
# get default gateway IP
$gateway=(gwmi Win32_networkAdapterConfiguration | ?{$_.IPEnabled}).DefaultIPGateway

# trim to the first two octets of default route
$gatewaynet = $gateway.split('.')
$gatewaynet = $gatewaynet[0,1]
$gatewaynet = $gatewaynet -join '.'

# get list of IPv4 addresses
$localipaddr=(gwmi Win32_NetworkAdapterConfiguration | ? { $_.IPAddress -ne $null }).ipaddress

# match IPv4 address to default gateway and make sure it's only one IP
$primaryip = $localipaddr -like "$gatewaynet*" | Select-Object -first 1

# lookup reverse dns record for that IP
$reversefqdn=(nslookup "$primaryip") -match "Name" | select-object -last 1
$reversefqdn = ($reversefqdn).split(" ") | select-object -last 1

# get the shortname
$new_hostname = $reversefqdn.split('.')
$new_hostname = $new_hostname[0]

# use primary IP reverse DNS name to rename the host
write-output "Changing Windows hostname to $new_hostname"
$ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem
$ComputerInfo.Rename($new_hostname)

# set dns search suffix
Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Domain" -value "example.com" -type string -Force
Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "SyncDomainWithMembership" -value "0" -type dword -Force

# Set time zone and sync clock with ntp
Write-Output "Setting System Time Zone to UTC `r"
tzutil.exe /s "UTC"

# configure NTP for local site
Write-Output "Setting System Time via NTP `r"
$DNS_SERVER = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'").DNSServerSearchOrder | Select-Object -first 1
Set-Service -Name "w32time" -StartupType Automatic -Status stopped
w32tm /config /manualpeerlist:$DNS_SERVER /syncfromflags:MANUAL
start-Service "w32time"
w32tm /resync

# Disable firewall
Write-Output "Configuring firewall... `r"
netsh advfirewall set allprofiles state off

# Set activation server
Write-Output "Setting KMS for CORP `r"
cscript C:\Windows\System32\slmgr.vbs /skms kms.example.com

# Clear windows autologon
Remove-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultDomainName -ea Silentlycontinue
Remove-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -ea Silentlycontinue
Remove-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -ea Silentlycontinue

# Make administrator user active for desktop OS
net user administrator /active:yes

# disable password never expires on administrator account
Get-WmiObject -Class Win32_UserAccount -Filter "name = 'administrator'" | Set-WmiInstance -Argument @{PasswordExpires = 1}

# set localuser user to not have expiring password. Sysprep resets this after customization
Write-Output "Setting localuser user to no-expire password `r"
net user localuser /expires:never /active:yes /logonpasswordchg:no

# extend disk 
$extendvolume=@(
    'select volume 1',
    'extend',
    'exit'
)
$extendvolume | diskpart

# stop logging
stop-transcript 

# exit with return code 1001
exit 1001
