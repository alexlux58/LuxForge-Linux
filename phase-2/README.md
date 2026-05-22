# Phase 2 — Base OS (LFS 13.0-systemd)

> Build the minimal bootable LuxForge Linux system from source.

This phase follows the official [LFS 13.0-systemd book](https://linuxfromscratch.org/lfs/view/stable-systemd/) start to finish. The output is a bootable, self-contained CLI Linux system installed on the dedicated LFS disk prepared in Phase 1.

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

## Notes

This section will be filled in as Phase 2 progresses.

---

→ Previous: [Phase 1 — Build Host](../phase-1/) | Next: [Phase 3 — BLFS Server Layer](../phase-3/)
