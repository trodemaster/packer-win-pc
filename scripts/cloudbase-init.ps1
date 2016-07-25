#download installer
$client = new-object System.Net.WebClient
$client.DownloadFile("https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi", "C:\windows\temp\CloudbaseInitSetup_Stable_x64.msi" )

# install the payload
start-process -FilePath 'c:\Windows\temp\CloudbaseInitSetup_Stable_x64.msi' -ArgumentList '/qn /l*v C:\windows\temp\cloud-init.log LOGGINGSERIALPORTNAME=COM1 USERNAME=admin' -passthru | wait-process

# verify that cloudbase-init tools exists
if (-not(test-path -path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts")){                                                                                                                                              
Write-output "cloudbase-init not installed exiting..."
exit 1
}   

move-item C:\Windows\Temp\cloudbase-init-unattend.conf "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.conf" -force
move-item C:\Windows\Temp\cloudbase-init.conf "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" -force
move-item C:\Windows\Temp\cloudbase-init-firstboot.ps1 "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\cloudbase-init-firstboot.ps1" -force
start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "config cloudbase-init start= demand" -wait
