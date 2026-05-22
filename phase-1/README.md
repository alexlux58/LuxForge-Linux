# Phase 1 — Build Host

> Prepare the dedicated build environment for LuxForge Linux.

This phase covers standing up the host VM, installing all LFS build dependencies, setting up the repo directory structure, and preparing the dedicated LFS target disk. No LFS source compilation happens here. The output is a configured host with all required tools installed and a clean, mounted, persistent ext4 filesystem ready for the LFS book to begin.

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

## Steps completed

1) [Clone the repo and create directory structure](#1-clone-the-repo-and-create-directory-structure)
2) [Install LFS host build dependencies](#2-install-lfs-host-build-dependencies)
3) [Prepare the dedicated LFS disk](#3-prepare-the-dedicated-lfs-disk)
4) [Run host readiness checks](#4-run-host-readiness-checks)
5) [Verification](#verification)

---

## 1) Clone the repo and create directory structure

```bash
git clone https://github.com/alexlux58/LuxForge-Linux.git
cd LuxForge-Linux
mkdir {docs,scripts,branding,logos,manifests,releases,upstream}
```

### Directory layout

| Directory | Purpose |
|---|---|
| `docs/` | Extended documentation, diagrams, design notes |
| `scripts/` | Build automation and helper scripts |
| `branding/` | OS identity files — os-release, motd, GRUB config |
| `logos/` | LuxForge Linux logo assets |
| `manifests/` | Package version manifests and wget-lists |
| `releases/` | Release notes, changelogs, versioned artifacts |
| `upstream/` | Upstream patch references and errata tracking |
| `phase-*/` | Per-phase notes and command logs |

---

## 2) Install LFS host build dependencies

The LFS book requires a specific set of host tools. These packages cover the full toolchain, compression utilities, scripting tools, and disk management utilities needed throughout the build.

```bash
sudo apt update
sudo apt install -y \
  bash binutils bison coreutils diffutils findutils gawk gcc g++ \
  grep gzip m4 make patch perl python3 sed tar texinfo xz-utils \
  gpg wget curl rsync git vim parted fdisk e2fsprogs mount kmod \
  build-essential file bzip2 xz-utils unzip bc
```

### Package groups

| Group | Packages |
|---|---|
| **Toolchain** | `binutils` `bison` `gcc` `g++` `make` `m4` `patch` |
| **Shell and scripting** | `bash` `gawk` `perl` `python3` `sed` |
| **File utilities** | `coreutils` `diffutils` `findutils` `grep` `gzip` `tar` `xz-utils` `bzip2` `unzip` `file` `bc` |
| **Documentation** | `texinfo` |
| **Crypto and networking** | `gpg` `wget` `curl` `rsync` `git` |
| **Editor** | `vim` |
| **Disk and storage** | `parted` `fdisk` `e2fsprogs` `mount` `kmod` |
| **Build meta** | `build-essential` |

### Why `bison` matters

`bison` is a parser generator used when building several LFS packages including GCC. It is not always pre-installed on Ubuntu hosts and must be explicitly added.

### Why `texinfo` matters

Several LFS packages install their documentation using `makeinfo`, which is provided by `texinfo`. Without it, certain package installs will fail or skip documentation installation.

### Verify key tool versions

After installing, the LFS book recommends checking that critical tools meet its minimum version requirements:

```bash
bash --version
ld --version
bison --version
chown --version
diff --version
find --version
gawk --version
gcc --version
g++ --version
ldd --version
grep --version
gzip --version
m4 --version
make --version
patch --version
perl --version
python3 --version
sed --version
tar --version
makeinfo --version
xz --version
```

The LFS book provides a `version-check.sh` script in Chapter 2 that automates this check. Run it before proceeding.

---

## 3) Prepare the dedicated LFS disk

### Storage background

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

### Commands

#### Inspect block devices

```bash
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS
```

`lsblk` lists block devices. Running this first confirms which disk is blank and which belong to Ubuntu. Useful alternatives: `lsblk -f`, `lsblk -p`.

#### Create a GPT partition table

```bash
sudo parted /dev/sdc --script mklabel gpt
```

Creates a fresh GPT partition table on the blank LFS disk. `--script` enables non-interactive mode. GPT is the current standard and more flexible than MBR.

#### Create the LFS partition

```bash
sudo parted /dev/sdc --script mkpart primary ext4 1MiB 100%
```

Creates one partition starting at `1MiB` (standard alignment offset) and filling the rest of the disk. The `ext4` string here is only a partition hint — the actual filesystem is created next.

#### Create the ext4 filesystem

```bash
sudo mkfs.ext4 -L LFSROOT /dev/sdc1
```

Formats the partition with ext4 and assigns the label `LFSROOT`. Using a label makes the fstab entry more readable and avoids relying on device letter ordering.

#### Create the mount point

```bash
sudo mkdir -p /mnt/lfs
```

Creates the directory the LFS filesystem will be mounted at. `-p` is idempotent.

#### Mount the filesystem

```bash
sudo mount /dev/sdc1 /mnt/lfs
```

Attaches the LFS filesystem to `/mnt/lfs`. LFS expects the target to be mounted throughout the build.

#### Persist the mount in `/etc/fstab`

```bash
echo 'LABEL=LFSROOT /mnt/lfs ext4 defaults 0 1' | sudo tee -a /etc/fstab
```

Appends an fstab entry so the filesystem remounts on boot. `tee` is used instead of `sudo echo >> /etc/fstab` because shell redirection happens before sudo is applied and fails on a root-owned file.

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

---

## 4) Run host readiness checks

A reusable host validation script is now tracked in this repo:

- Script: `scripts/host-check.sh`
- Purpose: quickly verify command availability, shell/link assumptions, PTY support, compiler sanity, and CPU count before entering LFS Chapter 5+

Run it with:

```bash
chmod +x ./scripts/host-check.sh
./scripts/host-check.sh
```

Recorded result summary:

- all required base commands reported `[OK]`
- kernel: `6.8.0-110-generic`
- shell/link sanity: `/bin/sh -> /usr/bin/dash`, `awk -> /usr/bin/gawk`, `yacc -> /usr/bin/bison.yacc`
- PTY support check passed
- compiler sanity (`g++` test compile) passed
- CPU cores: `4`

Exit code behavior:

- `0` = all checks passed
- `1` = at least one check failed

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

## Exact commands used (in order)

```bash
# Repo setup
git clone https://github.com/alexlux58/LuxForge-Linux.git
cd LuxForge-Linux
mkdir {docs,scripts,branding,logos,manifests,releases,upstream}

# Host dependencies
sudo apt update
sudo apt install -y \
  bash binutils bison coreutils diffutils findutils gawk gcc g++ \
  grep gzip m4 make patch perl python3 sed tar texinfo xz-utils \
  gpg wget curl rsync git vim parted fdisk e2fsprogs mount kmod \
  build-essential file bzip2 xz-utils unzip bc

# LFS disk setup
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS
sudo parted /dev/sdc --script mklabel gpt
sudo parted /dev/sdc --script mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 -L LFSROOT /dev/sdc1
sudo mkdir -p /mnt/lfs
sudo mount /dev/sdc1 /mnt/lfs
echo 'LABEL=LFSROOT /mnt/lfs ext4 defaults 0 1' | sudo tee -a /etc/fstab

# Verification
findmnt /mnt/lfs
lsblk -f
df -h

# Host readiness check
chmod +x ./scripts/host-check.sh
./scripts/host-check.sh
```

---

## Lessons learned

1. **Ubuntu installers can consume more disks than expected.** The initial install absorbed both disks into one LVM root. Adding a dedicated third disk was cleaner than reshaping the existing LVM.
2. **Always inspect storage before formatting.** Running `lsblk` first avoided formatting a disk already in use.
3. **A dedicated LFS target makes everything safer.** Isolation lowers risk and simplifies recovery.
4. **Thin-provisioned virtual disks are useful, but host storage still matters.** The hypervisor still needs real free space as the guest writes data.
5. **Install `bison` and `texinfo` explicitly.** Ubuntu does not always include them by default and both are required by LFS packages.
6. **Use a repeatable host check script.** Tracking `scripts/host-check.sh` makes readiness checks consistent before starting toolchain-heavy chapters.

---

→ Next: [Phase 2 — Base OS](../phase-2/)
