# Phase 1 — Build Host

> Prepare the dedicated build environment for LuxForge Linux.

This phase covers standing up the host VM and preparing the dedicated LFS target disk. No LFS source compilation happens here. The output is a clean, mounted, persistent ext4 filesystem ready for the LFS book to begin.

---

## Host specs

| Item | Value |
|---|---|
| **Hypervisor** | Proxmox VE |
| **Guest OS** | Ubuntu 24.04.3 LTS |
| **vCPU** | 4 minimum (LFS editors' recommendation) |
| **RAM** | 8–16 GB |
| **Host disk** | `sda` — Ubuntu system |
| **LFS target disk** | `sdc` — dedicated 25G virtual disk |
| **LFS mount point** | `/mnt/lfs` |

---

## Storage background

During the original Ubuntu install, the installer consumed both the 40G and 100G disks into a single Ubuntu LVM root volume. That was not ideal for LFS because the recommended approach is to keep the LFS target isolated from the host OS.

To fix that without reinstalling Ubuntu, a new **25G virtual disk** was added and dedicated entirely to LFS.

Final storage layout:

- `sda` = Ubuntu host disk
- `sdb` = part of the Ubuntu LVM volume group from the original install
- `sdc` = dedicated 25G LFS disk
- `sdc1` = ext4 filesystem, label `LFSROOT`
- `/mnt/lfs` = LFS mount point

A dedicated LFS target disk gives:

- lower risk of formatting the wrong device
- easier recovery if the build breaks
- simpler snapshots and rebuilds
- a clear mental model: Ubuntu is the **host**, `/mnt/lfs` is the **target**

---

## Commands

### 1) Inspect block devices

```bash
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS
```

`lsblk` lists block devices. Running this first confirms which disk is blank and which belong to Ubuntu. The flag `-o` selects output columns: `NAME` shows hierarchy, `SIZE` confirms the correct disk, `FSTYPE` shows whether a filesystem or LVM member already exists, `TYPE` separates disks from partitions, and `MOUNTPOINTS` shows what is already in use.

Useful alternatives:

```bash
lsblk
lsblk -f
lsblk -p
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS
```

---

### 2) Create a GPT partition table

```bash
sudo parted /dev/sdc --script mklabel gpt
```

Creates a fresh GPT partition table on the blank LFS disk. `--script` enables non-interactive mode for a repeatable workflow. GPT is the current standard and is more flexible than MBR.

Useful alternatives:

```bash
sudo fdisk /dev/sdc
sudo gdisk /dev/sdc
```

---

### 3) Create the LFS partition

```bash
sudo parted /dev/sdc --script mkpart primary ext4 1MiB 100%
```

Creates one partition starting at `1MiB` (standard alignment offset) and filling the rest of the disk. This command creates the partition entry only — the `ext4` string here is a hint in the partition metadata, not the actual filesystem.

---

### 4) Create the ext4 filesystem

```bash
sudo mkfs.ext4 -L LFSROOT /dev/sdc1
```

Formats the partition with ext4 and assigns the label `LFSROOT`. The LFS book assumes ext4 for the root. Using a label makes the fstab entry more readable and avoids relying on device letter ordering.

Useful alternatives:

```bash
sudo mkfs.ext4 /dev/sdc1
sudo mkfs.ext4 -L LFSROOT -m 0 /dev/sdc1   # reclaim reserved blocks
```

---

### 5) Create the mount point

```bash
sudo mkdir -p /mnt/lfs
```

Creates the directory that the LFS filesystem will be mounted at. The `-p` flag is idempotent — it does not fail if the directory already exists.

---

### 6) Mount the filesystem

```bash
sudo mount /dev/sdc1 /mnt/lfs
```

Attaches the LFS filesystem to `/mnt/lfs` so that the host can write into it. LFS expects the target to be mounted throughout the build.

Useful alternatives:

```bash
sudo mount LABEL=LFSROOT /mnt/lfs
sudo mount UUID=<uuid> /mnt/lfs
```

---

### 7) Persist the mount in `/etc/fstab`

```bash
echo 'LABEL=LFSROOT /mnt/lfs ext4 defaults 0 1' | sudo tee -a /etc/fstab
```

Appends an fstab entry so the filesystem remounts on boot. `tee` is used instead of `sudo echo >> /etc/fstab` because shell redirection happens before sudo is applied and would fail on a root-owned file.

Field breakdown:

```text
LABEL=LFSROOT   /mnt/lfs   ext4   defaults   0   1
```

1. `LABEL=LFSROOT` — identify filesystem by label
2. `/mnt/lfs` — mount point
3. `ext4` — filesystem type
4. `defaults` — standard mount options
5. `0` — skip legacy dump backup
6. `1` — fsck pass order at boot

Useful alternative (UUID-based, avoids any label collision):

```bash
sudo blkid /dev/sdc1
echo 'UUID=<uuid> /mnt/lfs ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

---

## Verification

```bash
findmnt /mnt/lfs   # confirm what is mounted at /mnt/lfs
lsblk -f           # show filesystem type, label, UUID, and mount point
df -h              # check available disk space
```

Expected results:

- `sdc1` listed as ext4 with label `LFSROOT`
- `/mnt/lfs` showing ~24G available
- mount source confirmed as `/dev/sdc1`

---

## Lessons learned

1. **Ubuntu installers can consume more disks than expected.** The initial install absorbed both disks into one LVM root. Adding a dedicated third disk was cleaner than reshaping the existing LVM.
2. **Always inspect storage before formatting.** Running `lsblk` first avoided formatting a disk already in use.
3. **A dedicated LFS target makes everything safer.** Isolation lowers risk and simplifies recovery.
4. **Thin-provisioned virtual disks are useful, but host storage still matters.** The hypervisor still needs real free space as the guest writes data.

---

## Exact commands used

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

→ Next: [Phase 2 — Base OS](../phase-2/)
