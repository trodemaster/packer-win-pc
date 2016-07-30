# packer-win-pc
***packer.io templates &amp; scripts for building private cloud optimized Windows OS images.***
If your unclear what packer templates are about check http://packer.io

This template is used to create both VMware ESXi and OpenStack/KVM templates of Windows 10. It utilzes Windows RM and PowerShell scripts to build the latest OS with the modern tools.

**Prerequsits**

You will need to have http://packer.io installed and the appropriate hypervisor. QEMU/KVM and VMware Workstation/Fusion/Player are ones you should have avialable. Linux systems that can have Workstation and QEMU/KVM are ideal as you can build both images at the same time given enough system resrouces. 

Extract the pvscsi and vmxnet3 drivers from VMware tools installer and popluate the FILES directory. 
https://kb.vmware.com/kb/2032184

Aquire a set of virtio windows drivers. Ideally install the virtio-win package on redhat and extract those as they are signed drivers. 

Populate the FILES with the drivers as shown below. These get written to a flopy image before the sysetem is booted. Downloading them after boot is not realistic. 
<pre>
FILES
├── pvscsi
│   ├── pvscsi.cat
│   ├── pvscsi.inf
│   ├── pvscsi.sys
│   ├── pvscsiver.dll
│   └── txtsetup.oem
├── virtio-win
│   └── Win8.1
│       ├── netkvm.cat
│       ├── netkvm.inf
│       ├── netkvm.sys
│       ├── vioscsi.cat
│       ├── vioscsi.inf
│       ├── vioscsi.sys
│       ├── viostor.cat
│       ├── viostor.inf
│       └── viostor.sys
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

***Building the images***
After configuring your build system with the required bits and prerequsits use the following commands to build the images. From the root of the git repo run the follwing commands. 

Quick validation of file paths...
<pre><code>packer validate -var-file privatedata.json Win10.json</pre></code>

Build both OpenStack and VMware images at the same time
<pre><code>packer build -force -var-file privatedata.json Win10.json</pre></code>

Build the VMware image only
<pre><code>packer build -force -var-file privatedata.json -only vmware-iso Win10.json</pre></code>

Build the OpenStack image only
<pre><code>packer build -force -var-file privatedata.json -only qemu Win10.json</pre></code>









