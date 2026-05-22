# Phase 2 Notes — Source Download and Verification

> Current milestone: Phase 2 is complete through source download and MD5 verification. The next LFS book step is creating the limited LFS directory layout.

This note captures the useful CLI input/output from the early Phase 2 work and explains what each command did, why it was used, and what to watch for. The full raw logs are tracked separately in:

- `phase-2/logs/download-sources.log`
- `phase-2/logs/md5sums.log`

---

## 1. Confirming the source directory

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ ll /sources/
total 8
drwxr-xr-x  2 root root 4096 May 22 19:17 ./
drwxr-xr-x 24 root root 4096 May 22 19:17 ../

alexlux@ubuntuvm:~/LuxForge-Linux$ ll $LFS/sources/
total 8
drwxr-xr-x 2 root root 4096 May 22 19:18 ./
drwxr-xr-x 4 root root 4096 May 22 19:18 ../

alexlux@ubuntuvm:~/LuxForge-Linux$ ls /mnt/lfs/
lost+found  sources

alexlux@ubuntuvm:~/LuxForge-Linux$ ls /mnt/lfs/sources/
```

### Explanation

`/sources` and `$LFS/sources` are not the same thing. For this build, `LFS=/mnt/lfs`, so the correct source directory is:

```bash
/mnt/lfs/sources
```

The root-level `/sources` directory was created accidentally and is not used by the LFS build. The LFS source packages should live under `$LFS/sources` so they remain inside the target filesystem and are available throughout the build.

### Command notes

- `ll` is usually an alias for `ls -alF` on Ubuntu.
- `$LFS` expands to the current LFS target path.
- `lost+found` is created automatically by ext filesystems and is normal.

---

## 2. Fixing `$LFS/sources` permissions

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ sudo chmod -v a+wt "$LFS/sources"
[sudo] password for alexlux:
mode of '/mnt/lfs/sources' changed from 0755 (rwxr-xr-x) to 1777 (rwxrwxrwt)
```

### Explanation

The LFS book expects `$LFS/sources` to be writable while also protected from users deleting each other's files. The permission mode `1777` is the same pattern used by `/tmp`.

### Flags and mode breakdown

```bash
sudo chmod -v a+wt "$LFS/sources"
```

- `sudo` runs the command as root because `$LFS/sources` is owned by root.
- `chmod` changes file or directory permissions.
- `-v` means verbose output, so the command prints what changed.
- `a+w` gives write permission to all users.
- `+t` sets the sticky bit.
- `"$LFS/sources"` quotes the path so the command remains safe if the variable ever contains spaces.

The sticky bit matters because it lets multiple users write into the directory, but prevents one user from deleting files owned by another user.

---

## 3. First failed source download attempt

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ wget --input-file=./wget-list-systemd --continue --directory-prefix="$LFS/sources"
./wget-list-systemd: No such file or directory
No URLs found in ./wget-list-systemd.
```

### Explanation

This failed because the current working directory was the repository root, but `wget-list-systemd` was stored under `upstream/`.

The command itself was valid; the relative path was wrong.

### Flag breakdown

```bash
wget --input-file=./wget-list-systemd --continue --directory-prefix="$LFS/sources"
```

- `wget` downloads files over HTTP, HTTPS, and FTP.
- `--input-file=FILE` tells `wget` to read a list of URLs from a file.
- `--continue` resumes partially downloaded files instead of restarting them from zero.
- `--directory-prefix=DIR` saves all downloads into the specified directory.

### Why these flags were used

The LFS project publishes an official `wget-list-systemd` file. Using it avoids manually downloading dozens of packages and patches one at a time. `--continue` is useful because a source download can be interrupted and resumed safely.

---

## 4. Running the source download from the correct directory

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ cd upstream/
alexlux@ubuntuvm:~/LuxForge-Linux/upstream$ wget --input-file=./wget-list-systemd --continue --directory-prefix="$LFS/sources"
```

Representative output:

```text
Saving to: ‘/mnt/lfs/sources/acl-2.3.2.tar.xz’
acl-2.3.2.tar.xz 100% ... saved [371680/371680]

Saving to: ‘/mnt/lfs/sources/binutils-2.46.0.tar.xz’
binutils-2.46.0.tar.xz 100% ... saved [28548776/28548776]

Saving to: ‘/mnt/lfs/sources/gcc-15.2.0.tar.xz’
gcc-15.2.0.tar.xz 100% ... saved [101056276/101056276]

Saving to: ‘/mnt/lfs/sources/linux-6.18.10.tar.xz’
linux-6.18.10.tar.xz 100% ... saved [154360116/154360116]

FINISHED --2026-05-22 19:55:53--
Total wall clock time: 4m 3s
Downloaded: 96 files, 604M in 38s (16.0 MB/s)
```

### Explanation

After changing into `upstream/`, the relative path `./wget-list-systemd` resolved correctly. Files were downloaded into `/mnt/lfs/sources`, which is the correct target source directory.

### Important observation

One URL returned a `404 Not Found` during the download:

```text
https://www.linuxfromscratch.org/lfs/downloads/13.0/lfs-bootscripts-20250827.tar.xz
ERROR 404: Not Found.
```

Because this is a **systemd** build, the next verification step is the source of truth. If `md5sum -c md5sums` passes for the expected systemd source set, the build can continue. If a missing file is listed in `md5sums`, stop and re-check whether the correct `wget-list-systemd` and `md5sums` files are being used from the same LFS release.

---

## 5. Checkpoint directory mistake

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ mkdir -p /logs/checkpoints
mkdir: cannot create directory ‘/logs’: Permission denied
```

### Explanation

This tried to create a directory directly under `/`, which is owned by root. That is why it failed.

The project log directory should be inside the Git repository:

```bash
logs/checkpoints
```

not:

```bash
/logs/checkpoints
```

### Correct pattern

```bash
cd ~/LuxForge-Linux
mkdir -p logs/checkpoints
```

Avoid using `sudo` for repo directories unless you intentionally want root-owned files. Root-owned files inside a normal Git repo commonly cause later permission issues.

---

## 6. Root-owned checkpoint directory issue

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ sudo mkdir -p logs/checkpoints
alexlux@ubuntuvm:~/LuxForge-Linux/logs$ date -Is | tee -a checkpoints/timeline.log
tee: checkpoints/timeline.log: Permission denied
2026-05-22T20:07:06+00:00
```

### Explanation

The directory was created with `sudo`, so it became owned by root. The normal user could not write `timeline.log` inside it.

`sudo date -Is | tee ...` did not fix it because only the `date` command ran with sudo. The `tee` process still ran as the normal user.

### Fix

```bash
cd ~/LuxForge-Linux
sudo chown -R "$USER:$USER" logs
mkdir -p logs/checkpoints
date -Is | tee -a logs/checkpoints/timeline.log
```

### Why this fix works

- `chown -R "$USER:$USER" logs` gives the repo log directory back to the normal user.
- `tee -a` appends to the checkpoint log and also prints to the terminal.
- No sudo is needed afterward because repo files should be user-owned.

---

## 7. Phase 2 manifest path issue

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ {
  echo "# Phase 2 Start Manifest"
  echo
  echo "Date: $(date -Is)"
  echo
  echo "## Host"
  uname -a
  echo
  echo "## Block Devices"
  lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS
  echo
  echo "## Mount"
  findmnt /mnt/lfs
  echo
  echo "## Disk Space"
  df -h /mnt/lfs
} | tee phase-2/manifests/phase-2-start.md
tee: phase-2/manifests/phase-2-start.md: No such file or directory
```

### Explanation

The command failed because `phase-2/manifests/` did not exist yet.

After changing into `phase-2/`, the correct path became:

```bash
manifests/phase-2-start.md
```

not:

```bash
phase-2/manifests/phase-2-start.md
```

### Successful CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux/phase-2$ mkdir -p {logs,manifests,notes}

alexlux@ubuntuvm:~/LuxForge-Linux/phase-2$ {
  echo "# Phase 2 Start Manifest"
  echo
  echo "Date: $(date -Is)"
  echo
  echo "## Host"
  uname -a
  echo
  echo "## Block Devices"
  lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS
  echo
  echo "## Mount"
  findmnt /mnt/lfs
  echo
  echo "## Disk Space"
  df -h /mnt/lfs
} | tee manifests/phase-2-start.md
```

Representative output:

```text
# Phase 2 Start Manifest

Date: 2026-05-22T20:23:39+00:00

## Host
Linux ubuntuvm 6.8.0-110-generic #110-Ubuntu SMP PREEMPT_DYNAMIC Thu Mar 19 15:09:20 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux

## Block Devices
NAME                       SIZE FSTYPE      TYPE MOUNTPOINTS
sda                         40G             disk
├─sda2                       2G ext4        part /boot
└─sda3                      38G LVM2_member part
  └─ubuntu--vg-ubuntu--lv  138G ext4        lvm  /
sdb                        100G             disk
└─sdb1                     100G LVM2_member part
  └─ubuntu--vg-ubuntu--lv  138G ext4        lvm  /
sdc                         25G             disk
└─sdc1                      25G ext4        part /mnt/lfs

## Mount
TARGET   SOURCE    FSTYPE OPTIONS
/mnt/lfs /dev/sdc1 ext4   rw,relatime

## Disk Space
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdc1        25G  605M   23G   3% /mnt/lfs
```

### Command notes

- `{ ... }` groups several commands so their combined output can be piped.
- `tee file` writes the output to a file and prints it to the terminal.
- `date -Is` prints an ISO-8601 timestamp.
- `uname -a` captures kernel and architecture information.
- `lsblk -o ...` records the storage layout.
- `findmnt /mnt/lfs` confirms the active LFS mount.
- `df -h /mnt/lfs` records available disk space.

---

## 8. Source verification

### CLI

```bash
alexlux@ubuntuvm:/mnt/lfs/sources$ md5sum -c md5sums
```

Representative output:

```text
acl-2.3.2.tar.xz: OK
attr-2.5.2.tar.gz: OK
binutils-2.46.0.tar.xz: OK
gcc-15.2.0.tar.xz: OK
glibc-2.43.tar.xz: OK
linux-6.18.10.tar.xz: OK
systemd-259.1.tar.gz: OK
util-linux-2.41.3.tar.xz: OK
vim-9.2.0078.tar.gz: OK
zstd-1.5.7.tar.gz: OK
bzip2-1.0.8-install_docs-1.patch: OK
coreutils-9.10-i18n-1.patch: OK
expect-5.45.4-gcc15-1.patch: OK
glibc-fhs-1.patch: OK
kbd-2.9.0-backspace-1.patch: OK
```

### Explanation

`md5sum -c md5sums` checks the downloaded source archives and patches against the official expected checksums.

### Flag breakdown

- `md5sum` computes or verifies MD5 checksums.
- `-c` means check mode: read checksums from the file and verify matching files exist with matching hashes.
- `md5sums` is the checksum manifest.

For LFS, this is a required trust-and-integrity checkpoint. A download can appear successful but still be incomplete, corrupted, or mismatched. The `OK` output confirms the source file matches the expected checksum.

---

## 9. Source ownership cleanup

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ sudo chown root:root "$LFS/sources"/*
```

### Explanation

This changes all downloaded source packages and patches to `root:root` ownership.

### Why this was used

Later in the build, user IDs inside the new LFS system may not match the host user's IDs. Setting the downloaded source files to root ownership avoids confusing ownership artifacts being carried into the target environment.

### Flags and syntax

- `sudo` is required because the target files are intended to become root-owned.
- `chown` changes owner and group.
- `root:root` sets owner to `root` and group to `root`.
- `"$LFS/sources"/*` expands to all files directly inside the source directory.

---

## 10. Git commit and push

### CLI

```bash
alexlux@ubuntuvm:~/LuxForge-Linux$ git add phase-2/logs/download-sources.log phase-2/logs/md5sums.log
alexlux@ubuntuvm:~/LuxForge-Linux$ git commit -m "Download and verify LFS source packages"
[main f44d911] Download and verify LFS source packages
 2 files changed, 1380 insertions(+)
 create mode 100644 phase-2/logs/download-sources.log
 create mode 100644 phase-2/logs/md5sums.log

alexlux@ubuntuvm:~/LuxForge-Linux$ git status
On branch main
Your branch is ahead of 'origin/main' by 3 commits.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  modified:   manifests/wget-list-systemd

alexlux@ubuntuvm:~/LuxForge-Linux$ git add .
alexlux@ubuntuvm:~/LuxForge-Linux$ git commit -m commit
[main 1324601] commit
 1 file changed, 97 insertions(+)

alexlux@ubuntuvm:~/LuxForge-Linux$ git push origin main
To https://github.com/alexlux58/LuxForge-Linux.git
   f259043..1324601  main -> main
```

### Explanation

This pushed the Phase 2 source download and verification logs to `origin/main`.

### Notes

The commit message `commit` worked, but future commits should use descriptive messages. Better examples:

```bash
git commit -m "Document Phase 2 source download and verification"
git commit -m "Add LFS source download logs"
git commit -m "Record Phase 2 source checksum verification"
```

---

## Current status

Complete:

- `$LFS/sources` exists
- sticky-bit permissions were applied
- sources were downloaded into `/mnt/lfs/sources`
- checksum verification passed
- source files were changed to `root:root`
- download and checksum logs were committed and pushed

Next:

- create the limited LFS directory layout
- create the `lfs` build user
- configure the clean build environment
- begin Chapter 5 with Binutils Pass 1

---

## Next command block: create the limited LFS directory layout

Run from the Ubuntu host as your normal user:

```bash
cd ~/LuxForge-Linux
export LFS=/mnt/lfs

sudo mkdir -pv "$LFS"/{etc,var} "$LFS"/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  if [ ! -e "$LFS/$i" ]; then
    sudo ln -sv "usr/$i" "$LFS/$i"
  fi
done

case "$(uname -m)" in
  x86_64)
    sudo mkdir -pv "$LFS/lib64"
    ;;
esac

sudo mkdir -pv "$LFS/tools"
```

### Why this layout exists

This creates the minimal filesystem skeleton required before building the temporary toolchain. On modern LFS, `/bin`, `/lib`, and `/sbin` are symlinks into `/usr`, matching the merged `/usr` layout. `$LFS/tools` is where the temporary cross-toolchain will be installed before the final system is built.

### Verify after running

```bash
ls -la "$LFS"
ls -la "$LFS/usr"
```

Expected highlights:

```text
bin -> usr/bin
lib -> usr/lib
sbin -> usr/sbin
etc/
var/
usr/
lib64/
tools/
```

Do not create `/usr/lib64`. For this LFS layout, only `$LFS/lib64` is expected on x86_64.
