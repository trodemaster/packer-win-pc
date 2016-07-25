# packer-win-pc
packer.io templates &amp; scripts for building private cloud optimized Windows OS images


**Prerequsits**


Extract the pvscsi and vmxnet 3 drivers from VMware tools and popluate the FILES directory. 
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
<pre>
```
ISO
├── RELEASE_CLIENTENTERPRISE_OEM_X64FRE_EN-US.ISO
└── RELEASE_SERVER_OEM_X64FRE_EN-US.ISO
```
