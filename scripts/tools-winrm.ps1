# install vmware tools
write-output "Starting VMare Tools install"

## Download vmware tools
$client = new-object System.Net.WebClient
$client.DownloadFile("https://packages.vmware.com/tools/releases/latest/windows/x64/VMware-tools-10.0.9-3917699-x86_64.exe", "C:\windows\temp\setup64.exe" )

#Write-host "Installing VMware Tools..."
start-process -FilePath 'C:/Windows/Temp/setup64.exe' -ArgumentList '/S /v "/qn /l*v ""C:\windows\temp\vmwtoolsinstall.log"" ADDLOCAL=ALL REMOVE=Hgfs REBOOT=R"'