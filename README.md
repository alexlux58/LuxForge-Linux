# LuxForge Linux: Building Linux From Scratch on Proxmox

> A hands-on Linux From Scratch (LFS) project by Alex Lux, built in a Proxmox-hosted Ubuntu VM as a way to deepen Linux internals knowledge, release engineering discipline, and systems troubleshooting.

## Project goal

This project is the foundation for **LuxForge Linux** — a custom Linux From Scratch build and future branded distribution concept. The goal is not just to produce a bootable Linux system, but to understand each layer involved in building one:

- storage layout
- partitions and filesystems
- host build requirements
- source-based system assembly
- bootstrapping a toolchain
- reproducibility and documentation

For employers, this project demonstrates practical Linux administration, systems thinking, troubleshooting, and disciplined technical documentation. For learners, it shows how to prepare a safe build environment before starting the actual LFS book.

---

## What Linux From Scratch is

Linux From Scratch is a project and book that walks you through building a Linux system manually from source code. It is not a distro installer. It is a guided process for assembling your own Linux userspace and toolchain from the ground up. The current stable systemd branch is **LFS 13.0-systemd**, and BLFS 13.0 is the follow-on book used to extend the base system with networking tools, desktop packages, and other software.

---

## What is needed for LFS

Based on the official LFS guidance, a practical first build should have:

- a dedicated Linux host or Linux VM
- at least **4 CPU cores**
- at least **8 GB RAM**
- a dedicated partition or disk for the LFS target
- enough free disk for sources, temporary compilation artifacts, and the installed system
- the official LFS book, source manifest, and checksums
- patience, snapshots, and a reproducible workflow

The LFS editors recommend at least four cores and 8 GB of memory. A minimal LFS system needs around **10 GB**, and **30 GB is a reasonable size for growth**. The book also recommends using a dedicated partition, and notes that first-time users should avoid more complex storage designs like LVM or RAID for the LFS target if they can. LFS provides official `wget-list` and `md5sums` files for downloading and verifying the exact source set.

---

## My lab setup

This project is being built in a **Proxmox** virtual machine running **Ubuntu 24.04.3 LTS** as the build host.

### Host architecture

- **Hypervisor:** Proxmox VE
- **Guest OS:** Ubuntu 24.04.3 LTS
- **Build model:** Ubuntu host + dedicated LFS target disk
- **LFS mount point:** `/mnt/lfs`

### Initial storage issue

During the original Ubuntu install, the installer consumed both the 40G and 100G disks into a single Ubuntu LVM root volume. That was not ideal for LFS, because the recommended approach is to keep the LFS target isolated from the host OS.

### Fix applied

To correct that without reinstalling Ubuntu, I added a **new 25G disk** and dedicated it entirely to LFS.

Final working layout:

- `sda` = Ubuntu host disk
- `sdb` = also part of the Ubuntu LVM volume group from the original install
- `sdc` = dedicated **25G LFS disk**
- `sdc1` = ext4 filesystem labeled `LFSROOT`
- `/mnt/lfs` = mount point for the LFS target

After preparation, verification showed that `/mnt/lfs` was mounted from `/dev/sdc1` with roughly **24G available**, which is a solid size for a first LFS build.

---

## Why this storage design matters

LFS is much easier to manage when the target filesystem is isolated.

Benefits of a dedicated LFS disk:

- lower risk of formatting the wrong device
- easier recovery if the build breaks
- simpler documentation
- easier to snapshot and rebuild
- clearer mental model: Ubuntu is the **host**, `/mnt/lfs` is the **target**

This is especially useful for first-time builds.

---

## Phase 1: Preparing the dedicated LFS disk

The following commands were used to identify the new disk, partition it, format it, mount it, and make it persistent across reboots.

---

## Command-by-command breakdown

### 1) Inspect block devices

```bash
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS
```

### What it does

`lsblk` lists block devices such as disks, partitions, LVM volumes, and optical devices.

### Why this command was used

Before creating a filesystem, I needed to confirm:

- which disk was the new empty LFS disk
- which disks already belonged to Ubuntu
- whether the new disk already had a filesystem or partitions

This prevented accidentally formatting a disk already in use.

### Flag breakdown

- `-o` = choose which output columns to display
- `NAME` = device name, such as `sda`, `sdb`, `sdc1`
- `SIZE` = capacity of the disk or partition
- `FSTYPE` = filesystem or membership type, such as `ext4`, `LVM2_member`, or `iso9660`
- `TYPE` = disk, partition, lvm, rom
- `MOUNTPOINTS` = where the device is mounted

### Why these columns were useful

This exact column set gives a fast storage map:

- **NAME** shows hierarchy
- **SIZE** confirms the correct disk
- **FSTYPE** shows whether the device is already formatted or used by LVM
- **TYPE** distinguishes disks from partitions
- **MOUNTPOINTS** shows what is already in use

### Useful alternatives

```bash
lsblk
lsblk -f
lsblk -p
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS
```

Use cases:

- `lsblk` → quick default view
- `lsblk -f` → filesystem-focused view
- `lsblk -p` → full device paths like `/dev/sdc1`
- extra columns like `MODEL` or `SERIAL` → useful on physical servers

---

### 2) Create a GPT partition table

```bash
sudo parted /dev/sdc --script mklabel gpt
```

### What it does

This creates a new **GPT partition table** on `/dev/sdc`.

A partition table is the structure that tells the OS where partitions start and end on the disk.

### Why this command was used

The new disk was blank. Before creating a filesystem, the disk first needed a partition layout.

GPT was chosen because it is the current standard and is more flexible than MBR.

### Flag breakdown

- `sudo` = required because disk partitioning needs root privileges
- `parted` = partition editor for disks
- `/dev/sdc` = target disk
- `--script` = non-interactive mode; do not prompt
- `mklabel` = create a partition table label
- `gpt` = use a GUID Partition Table

### Why `--script` was used

For a repeatable LFS workflow, non-interactive commands are better than manually typing inside an interactive shell.

### Useful alternatives

```bash
sudo fdisk /dev/sdc
sudo cfdisk /dev/sdc
sudo gdisk /dev/sdc
```

Use cases:

- `fdisk` → classic interactive partitioning
- `cfdisk` → friendlier text UI
- `gdisk` → GPT-specific interactive tool

---

### 3) Create the LFS partition

```bash
sudo parted /dev/sdc --script mkpart primary ext4 1MiB 100%
```

### What it does

This creates one partition on `/dev/sdc` that starts at **1 MiB** and ends at **100%** of the disk.

### Important clarification

This command does **not** create the ext4 filesystem. It creates the partition entry and marks its intended type/hint. The actual filesystem is created later by `mkfs.ext4`.

### Flag breakdown

- `mkpart` = make a new partition
- `primary` = partition name/type role
- `ext4` = filesystem hint/type string for the partition metadata
- `1MiB` = start offset
- `100%` = use the rest of the disk

### Why `1MiB` was used

Starting at `1MiB` is a common alignment best practice. It avoids awkward sector alignment problems and plays nicely with modern disks, SSDs, and virtual disks.

### Why `100%` was used

This was a simple single-purpose LFS disk, so using the entire remaining disk made sense.

### Useful alternatives

```bash
sudo parted /dev/sdc --script mkpart primary ext4 1MiB 20GiB
sudo parted /dev/sdc --script print
```

Use cases:

- fixed-size partition if you want room for more partitions later
- `print` to review the partition table

---

### 4) Create the ext4 filesystem

```bash
sudo mkfs.ext4 -L LFSROOT /dev/sdc1
```

### What it does

This formats `/dev/sdc1` with the **ext4** filesystem and assigns it the label `LFSROOT`.

### Why ext4 was used

The LFS book assumes an ext4 root filesystem, and ext4 is a solid default for general-purpose Linux systems.

### Flag breakdown

- `mkfs.ext4` = create an ext4 filesystem
- `-L LFSROOT` = assign the filesystem label `LFSROOT`
- `/dev/sdc1` = target partition

### Why a label was used

Using a label makes the mount entry more readable than a raw device path. It also avoids depending on Linux always assigning the same disk letter ordering.

### Useful alternatives

```bash
sudo mkfs.ext4 /dev/sdc1
sudo mkfs.ext4 -L LFSROOT -m 0 /dev/sdc1
sudo mkfs.xfs /dev/sdc1
sudo mkswap /dev/sdc2
```

Use cases:

- no label if you do not care about friendly names
- `-m 0` can reclaim reserved blocks on non-root data filesystems
- `xfs` for other workloads, though LFS commonly uses ext4
- `mkswap` if creating swap

---

### 5) Create the mount point

```bash
sudo mkdir -p /mnt/lfs
```

### What it does

Creates the directory where the new filesystem will be mounted.

### Flag breakdown

- `mkdir` = make directory
- `-p` = create parent directories as needed and do not fail if the directory already exists

### Why `-p` was used

It is idempotent. Running it again does not break anything.

### Useful alternatives

```bash
sudo mkdir /mnt/lfs
```

This works too, but it fails if the directory already exists.

---

### 6) Mount the filesystem

```bash
sudo mount /dev/sdc1 /mnt/lfs
```

### What it does

Attaches the filesystem on `/dev/sdc1` to the directory `/mnt/lfs`, making it accessible to the host OS.

### Why this command was used

LFS expects the target filesystem to be mounted so packages, tools, and directories can be built under that path.

### Useful alternatives

```bash
sudo mount -t ext4 /dev/sdc1 /mnt/lfs
sudo mount LABEL=LFSROOT /mnt/lfs
sudo mount UUID=66756531-a3f3-4a82-aeef-ea72ef873b4d /mnt/lfs
```

Use cases:

- `-t ext4` explicitly declares filesystem type
- `LABEL=` is readable
- `UUID=` is the most collision-resistant identifier

---

### 7) Persist the mount in `/etc/fstab`

```bash
echo 'LABEL=LFSROOT /mnt/lfs ext4 defaults 0 1' | sudo tee -a /etc/fstab
```

### What it does

Appends a new line to `/etc/fstab` so the filesystem can be mounted automatically on boot.

### Flag breakdown

- `echo` = prints the fstab line
- `|` = pipes the output to the next command
- `sudo tee -a /etc/fstab`
  - `tee` = writes stdin to a file and stdout
  - `-a` = append, do not overwrite
  - `sudo` = needed because `/etc/fstab` is root-owned

### Why `tee` was used instead of `sudo echo ... >> /etc/fstab`

Because shell redirection (`>>`) happens before `sudo` is applied. This fails in many cases. `tee` is the safe pattern.

### Field breakdown for the fstab line

```text
LABEL=LFSROOT   /mnt/lfs   ext4   defaults   0   1
```

Meaning:

1. `LABEL=LFSROOT` = identify the filesystem by label
2. `/mnt/lfs` = mount point
3. `ext4` = filesystem type
4. `defaults` = standard mount options
5. `0` = do not use the old `dump` backup utility
6. `1` = fsck pass order at boot

### Note on the last field

Alternative fstab line (common host-side convention, **not** the command executed above) for a non-root ext4 data filesystem:

```fstab
LABEL=LFSROOT /mnt/lfs ext4 defaults 0 2
```

That tells `fsck` to check it after the root filesystem. Your current entry is still valid and follows the style shown in the LFS book example, but `0 2` is often the cleaner host-side convention for a non-root LFS build partition.

### Useful alternatives

```bash
echo 'UUID=66756531-a3f3-4a82-aeef-ea72ef873b4d /mnt/lfs ext4 defaults 0 2' | sudo tee -a /etc/fstab
sudo blkid /dev/sdc1
```

Use cases:

- `UUID=` if you want stronger uniqueness than a label
- `blkid` to discover UUIDs and labels

---

## Verification commands

### 1) Check the active mount

```bash
findmnt /mnt/lfs
```

**Purpose:** confirm what is mounted at `/mnt/lfs`.

Why it is useful:

- cleaner than `mount | grep lfs`
- shows source, target, filesystem, and options

---

### 2) Check filesystem metadata

```bash
lsblk -f
```

**Purpose:** show filesystem types, labels, UUIDs, and mount points.

Why it is useful:

- confirms that `sdc1` is ext4
- confirms the `LFSROOT` label
- confirms the mount point

---

### 3) Check available disk space

```bash
df -h
```

### Flag breakdown

- `df` = disk free
- `-h` = human-readable sizes

**Purpose:** validate that the mount is usable and has the expected free space.

---

## What my results showed

The final storage verification showed:

- the new 25G disk appeared as `sdc`
- the new partition was `sdc1`
- `sdc1` was formatted as ext4
- the label `LFSROOT` was applied
- `/mnt/lfs` was mounted successfully
- roughly **24G** was available for the LFS build

That is a clean Phase 1 result and a good starting point for the actual LFS book.

---

## Lessons learned so far

### 1) Ubuntu installers can consume more disks than expected

The initial install absorbed both the 40G and 100G disks into one LVM root. That works for Ubuntu, but it is not a clean first-time LFS layout.

### 2) Always inspect storage before formatting

Running `lsblk` first avoided destroying a disk already in use.

### 3) A dedicated LFS target makes the project safer

Adding a small dedicated disk was a better move than trying to reshape the Ubuntu LVM root.

### 4) Thin-provisioned virtual disks are useful, but host storage still matters

Even when a virtual disk is sparse, the host still needs enough real free space as the guest writes data.

---

## Recommended next steps

With storage prepared, the next LFS steps are:

1. set the `LFS` environment variable
2. create the standard LFS source directory structure
3. download the official package set using `wget-list`
4. verify sources with `md5sums`
5. create the `lfs` build user
6. build the temporary toolchain
7. chroot into the new environment
8. build the final base system
9. configure boot, networking, and system identity
10. move into BLFS for additional packages

---

## Why this project matters

This project is valuable because it demonstrates more than “I installed Linux.”

It shows:

- comfort with block devices, filesystems, and mount persistence
- ability to detect and correct a storage design mistake safely
- understanding of Linux build environments
- ability to document work clearly for both technical and non-technical readers
- willingness to learn Linux at the component level instead of only through packaged abstractions

---

## References

- Linux From Scratch 13.0-systemd: https://linuxfromscratch.org/lfs/view/stable-systemd/
- Beyond Linux From Scratch 13.0-systemd: https://linuxfromscratch.org/blfs/view/stable-systemd/
- LFS host system requirements: https://linuxfromscratch.org/lfs/view/stable-systemd/chapter02/hostreqs.html
- LFS partitioning, filesystem, and mounting guidance: https://linuxfromscratch.org/lfs/view/stable-systemd/chapter02/creatingpartition.html

---

## Appendix: exact commands used

```bash
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS

sudo parted /dev/sdc --script mklabel gpt
sudo parted /dev/sdc --script mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 -L LFSROOT /dev/sdc1
sudo mkdir -p /mnt/lfs
sudo mount /dev/sdc1 /mnt/lfs
echo 'LABEL=LFSROOT /mnt/lfs ext4 defaults 0 1' | sudo tee -a /etc/fstab

findmnt /mnt/lfs
lsblk -f
df -h
```

---

More phases will be added as the LuxForge Linux build progresses.
