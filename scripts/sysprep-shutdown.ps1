# Kick off sysprep 
start-process -FilePath 'C:/windows/System32/Sysprep/sysprep.exe' -ArgumentList '/oobe /generalize /shutdown "/unattend:C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml"'
exit 0