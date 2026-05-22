# Phase 2 Start Manifest

Date: 2026-05-22T20:23:39+00:00

## Host
Linux ubuntuvm 6.8.0-110-generic #110-Ubuntu SMP PREEMPT_DYNAMIC Thu Mar 19 15:09:20 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux

## Block Devices
NAME                       SIZE FSTYPE      TYPE MOUNTPOINTS
sda                         40G             disk 
├─sda1                       1M             part 
├─sda2                       2G ext4        part /boot
└─sda3                      38G LVM2_member part 
  └─ubuntu--vg-ubuntu--lv  138G ext4        lvm  /
sdb                        100G             disk 
└─sdb1                     100G LVM2_member part 
  └─ubuntu--vg-ubuntu--lv  138G ext4        lvm  /
sdc                         25G             disk 
└─sdc1                      25G ext4        part /mnt/lfs
sr0                        2.6G iso9660     rom  

## Mount
TARGET   SOURCE    FSTYPE OPTIONS
/mnt/lfs /dev/sdc1 ext4   rw,relatime

## Disk Space
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdc1        25G  605M   23G   3% /mnt/lfs
