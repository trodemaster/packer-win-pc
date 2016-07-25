#Powershell version of install cleanup_compact 

# get the windows kernel version
$KERNELVERSION = [Environment]::OSVersion.Version

get-packageprovider -name chocolatey -ForceBootstrap
install-package sdelete -force
#install-package ultradefrag -force

# unzip function
function punzip( $zipfile, $outdir ) {
  If(-not(Test-Path -path $zipfile)){return "zipfile " + $zipfile + " not found!"}
  If(-not(Test-Path -path $outdir)){return "output dir " + $outdir + " not found!"}
  $shell = new-object -com shell.application
  $zip = $shell.NameSpace($zipfile)
  foreach($item in $zip.items())
    {
      $shell.Namespace($outdir).copyhere($item)
    }
}

## Download the FILES
$client = new-object System.Net.WebClient
$client.DownloadFile("http://downloads.sourceforge.net/project/ultradefrag/stable-release/7.0.1/ultradefrag-portable-7.0.1.bin.amd64.zip", "C:\windows\temp\ultradefrag-portable-7.0.1.bin.amd64.zip" )

# Stops the windows update service.  
Stop-Service -Name wuauserv -Force -EA 0 
Get-Service -Name wuauserv

# Delete the contents of windows software distribution.
write-output "Delete the contents of windows software distribution" 
Get-ChildItem "C:\Windows\SoftwareDistribution\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | remove-item -force -recurse -ErrorAction SilentlyContinue 

# Delete the contents of localuser apps.
write-output "Delete the contents of localuser apps" 
Get-ChildItem "C:\users\localuser\AppData\Local\Packages\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | remove-item -force -recurse -ErrorAction SilentlyContinue 

# Delete the contents of user template desktop.
write-output "Delete the contents of user template desktop"
Get-ChildItem "C:\Users\Public\Desktop\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | remove-item -force -recurse -ErrorAction SilentlyContinue 
 
# Starts the Windows Update Service 
Start-Service -Name wuauserv -EA 0

# use dism to cleanup windows sxs. This only works on 2012r2 and 8.1 and above. 
# bumped up to windows 10 only as was failing on 2012r2
if ([Environment]::OSVersion.Version -ge [Version]"10.0") {
  write-output "Cleaning up winSXS with dism"
  dism /online /cleanup-image /startcomponentcleanup /resetbase /quiet
}

# extract ultradefrag archive
write-output "extracting ultradefrag archive"
punzip ("C:\windows\temp\ultradefrag-portable-7.0.1.bin.amd64.zip") ("C:\Windows\temp")

# Defragment the virtual disk blocks
write-output "Starting to Defragment Disk"
start-process -FilePath 'C:\Windows\Temp\ultradefrag-portable-7.0.1.amd64\udefrag.exe' -ArgumentList '--optimize --repeat C:' -wait -verb RunAs
  
# Zero dirty blocks
write-output "Starting to Zero blocks"
#New-Item -Path "HKCU:\Software\Sysinternals\SDelete" -force -ErrorAction SilentlyContinue
#Set-ItemProperty -Path "HKCU:\Software\Sysinternals\SDelete" -Name EulaAccepted -Value "1" -Type DWORD -force
start-process -FilePath 'C:\Chocolatey\bin\sdelete64.bat' -ArgumentList '-q -z C:' -wait -EA 0
uninstall-package sdelete -force

exit 0



