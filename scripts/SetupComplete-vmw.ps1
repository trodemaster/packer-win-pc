# if you create custom ovfEnv properties in your template you can easily turn them into Environment variables for fun automation possibiliites. 

# read properties from vmware tools and store as xml
& "C:\Program Files\VMware\VMware Tools\vmtoolsd.exe" --cmd "info-get guestinfo.ovfEnv" 2>&1 | tee-object -variable vmtoolsxml | out-null
[xml]$vmtoolsxml = $vmtoolsxml

# turn all properties into ps Environment variables
foreach( $property in $vmtoolsxml.Environment.PropertySection.SelectNodes("*")){
$ps_varname = ($property.key | %{$_ -replace "vm.",""} | %{$_ -replace "\.","_"} )    
new-variable -name $ps_varname -value $property.value
}



exit 0