# packer-win-pc
***packer.io templates &amp; scripts for building private cloud optimized Windows OS images.***
If your unclear what packer templates are about check http://packer.io

This template is used to create both VMware ESXi and OpenStack/KVM templates of Windows 10. It utilzes Windows RM and PowerShell scripts to build the latest OS with the modern tools.

**Prerequsits**

Extract the pvscsi and vmxnet3 drivers from VMware tools installer and popluate the FILES directory. 
https://kb.vmware.com/kb/2032184

<pre>
  FILES
  ├── pvscsi
  │   ├── pvscsi.cat
  │   ├── pvscsi.inf
  │   ├── pvscsi.sys
  │   └── pvscsiver.dll
  └── vmxnet3
      ├── vmxnet3n61x64.sys
      ├── vmxnet3n61x86.sys
      ├── vmxnet3ndis6.cat
      ├── vmxnet3ndis6.inf
      └── vmxnet3ndis6ver.dll
</pre>

Grab your installer .iso files and put them in the ISO directory. 
<pre>
ISO
├── RELEASE_CLIENTENTERPRISE_OEM_X64FRE_EN-US.ISO
└── RELEASE_SERVER_OEM_X64FRE_EN-US.ISO
</pre>

***Required changes to the template file***
ISO filename
You must edit the Win10.json file to inclued the correct path to your Windows 10 .iso file. Make sure to update both builders. Additionally update the sha256 checksum that matches your .iso. 

***Private data***
In this example the only private data is the password used for local administrator and "localuser" user account. Copy the Example-privatedate.json to privatedata.json in the root of the directory. Add your own password here and the file will be ignored by git. Follow this practice for any other data you do not want in your repo.  