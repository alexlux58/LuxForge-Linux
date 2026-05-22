# Phase 2 — Base OS (LFS 13.0-systemd)

> Build the minimal bootable LuxForge Linux system from source.

This phase follows the official [LFS 13.0-systemd book](https://linuxfromscratch.org/lfs/view/stable-systemd/) start to finish. The output is a bootable, self-contained CLI Linux system installed on the dedicated LFS disk prepared in Phase 1.

---

## Current status

Phase 2 is complete through **source download and MD5 verification**.

| Task | Status | Notes |
|---|---:|---|
| Confirm `$LFS=/mnt/lfs` target | ✅ | LFS target mounted on `/dev/sdc1` |
| Prepare `$LFS/sources` | ✅ | Sticky-bit permissions applied: `1777` |
| Download LFS source packages | ✅ | 96 files downloaded into `/mnt/lfs/sources` |
| Verify source checksums | ✅ | `md5sum -c md5sums` returned `OK` for expected files |
| Commit source logs | ✅ | `phase-2/logs/download-sources.log` and `phase-2/logs/md5sums.log` committed |
| Create limited LFS directory layout | ⏭️ Next | Creates `/etc`, `/var`, `/usr`, `/tools`, and merged-`/usr` symlinks |

Detailed notes for this milestone are tracked here:

- [Source download and verification notes](notes/01-source-download-and-verification.md)
- [Download log](logs/download-sources.log)
- [Checksum log](logs/md5sums.log)

---

## Overview

| Step | Description |
|---|---|
| Set environment | Export `LFS=/mnt/lfs`, create `$LFS/sources`, download sources |
| Verify sources | Check `md5sums` against the official LFS manifest |
| Create build user | Unprivileged `lfs` user for the temporary toolchain |
| Temporary toolchain | Cross-compile binutils, GCC, glibc, and core tools into `$LFS/tools` |
| Chroot preparation | Set up virtual filesystems, enter the chroot environment |
| Final system | Build all LFS packages inside the chroot |
| System configuration | Hostname, network, locale, clock, bootloader |
| Boot test | Reboot from the LFS disk and verify the system comes up |

---

## Key book guidance

- Use the **exact package versions** listed in the book. Swapping versions can break build commands.
- Check the [LFS errata](https://linuxfromscratch.org/lfs/errata/stable-systemd/) for any updates before each package.
- Run the **test suites** for binutils, GCC, and glibc. These take time but catch toolchain problems early.
- Take hypervisor **snapshots** before each major step.

---

## Completed CLI highlights

### Prepare source directory permissions

```bash
sudo chmod -v a+wt "$LFS/sources"
```

Output:

```text
mode of '/mnt/lfs/sources' changed from 0755 (rwxr-xr-x) to 1777 (rwxrwxrwt)
```

Why this matters: `$LFS/sources` needs to be writable during the build while still protecting files from accidental deletion by other users. The sticky bit gives it `/tmp`-style behavior.

### Download sources from the official manifest

```bash
cd ~/LuxForge-Linux/upstream
wget --input-file=./wget-list-systemd --continue --directory-prefix="$LFS/sources"
```

Result summary:

```text
Downloaded: 96 files, 604M in 38s (16.0 MB/s)
```

The initial attempt failed from the repo root because `./wget-list-systemd` was not in that directory. Running the same command from `upstream/` fixed the relative path.

### Verify checksums

```bash
cd /mnt/lfs/sources
md5sum -c md5sums
```

Representative output:

```text
acl-2.3.2.tar.xz: OK
binutils-2.46.0.tar.xz: OK
gcc-15.2.0.tar.xz: OK
glibc-2.43.tar.xz: OK
linux-6.18.10.tar.xz: OK
systemd-259.1.tar.gz: OK
util-linux-2.41.3.tar.xz: OK
zstd-1.5.7.tar.gz: OK
```

Why this matters: source downloads must be validated before the toolchain build. A partially downloaded or mismatched archive can waste hours later.

### Normalize source ownership

```bash
sudo chown root:root "$LFS/sources"/*
```

Why this matters: source files become root-owned so host user IDs do not leak into the LFS target environment.

---

## Next step — create the limited LFS directory layout

Run from the Ubuntu host as the normal user:

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

### What this creates

| Path | Purpose |
|---|---|
| `$LFS/etc` | Early system configuration files |
| `$LFS/var` | Variable runtime/state data |
| `$LFS/usr/bin` | User command binaries |
| `$LFS/usr/lib` | Libraries |
| `$LFS/usr/sbin` | System administration binaries |
| `$LFS/bin -> usr/bin` | Merged-`/usr` compatibility symlink |
| `$LFS/lib -> usr/lib` | Merged-`/usr` compatibility symlink |
| `$LFS/sbin -> usr/sbin` | Merged-`/usr` compatibility symlink |
| `$LFS/lib64` | Required on x86_64 for 64-bit dynamic linker paths |
| `$LFS/tools` | Temporary cross-toolchain install prefix |

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

Do **not** create `/usr/lib64`. For this LFS layout, only `$LFS/lib64` is expected on x86_64.

---

## Notes

- Keep raw command output in `phase-2/logs/`.
- Keep explanations and troubleshooting notes in `phase-2/notes/`.
- Avoid committing source tarballs from `/mnt/lfs/sources`; they are large and reproducible from the official LFS manifest.
- Prefer descriptive commit messages over generic messages like `commit`.

---

→ Previous: [Phase 1 — Build Host](../phase-1/) | Next: [Phase 3 — BLFS Server Layer](../phase-3/)
