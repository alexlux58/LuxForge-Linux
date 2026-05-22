# LuxForge Linux

> **Codename: Aurelux** — a custom Linux From Scratch build by Alex Lux.

LuxForge Linux is not a prebuilt distro. It is a personal Linux system forged from source code using the official [Linux From Scratch](https://linuxfromscratch.org/) books. The goal is a minimal, branded, bootable x86_64 server OS built entirely from scratch — every package compiled, every config intentional.

---

## Brand

| Element | Value |
|---|---|
| **Name** | LuxForge Linux |
| **Codename** | Aurelux |
| **Colors** | Obsidian black · Steel gray · Electric cyan · Warm gold |
| **Tone** | Minimal · Technical · Sharp |
| **Logo** | Stylized L+X monogram or forged hexagon badge |

---

## The books

### LFS — Linux From Scratch

[LFS 13.0-systemd](https://linuxfromscratch.org/lfs/view/stable-systemd/) is the current stable release (March 5, 2026). It is a guided, step-by-step book for building a complete Linux system from source. It covers everything from host requirements and partitioning through cross-toolchain bootstrapping, chroot, and a fully bootable base system.

Key things to know before starting:

- **Use the exact package versions the book specifies.** Swapping versions can break commands or require errata changes.
- **Check errata and advisories** at [linuxfromscratch.org/lfs/errata](https://linuxfromscratch.org/lfs/errata/stable-systemd/) before and during the build.
- **Run test suites** for critical toolchain components — binutils, GCC, and glibc. They take time but they matter.
- The book measures build time in **SBUs** (Software Build Units). Plan accordingly.
- LFS does not install a package manager by default. The book describes techniques for managing packages using staged install trees and archives.
- **Target x86_64.** ARM can work but requires modifications the book does not cover by default.
- The LFS editors recommend at least **4 CPU cores** and **8 GB RAM**.

### BLFS — Beyond Linux From Scratch

[BLFS 13.0-systemd](https://linuxfromscratch.org/blfs/view/stable-systemd/) is the follow-on book. After LFS gives you a bootable CLI system, BLFS guides you through adding the software that makes it useful: networking tools, SSH, a package manager approach, graphical interfaces, sound, printers, and more.

This project uses BLFS in Phase 3 to add a small but practical server layer on top of the base LFS system.

---

## Project phases

| Phase | Folder | Status |
|---|---|---|
| 1 — Build host | [phase-1/](phase-1/) | ✅ Complete |
| 2 — Base OS (LFS 13.0-systemd) | [phase-2/](phase-2/) | 🔜 Upcoming |
| 3 — BLFS server layer | [phase-3/](phase-3/) | 🔜 Upcoming |
| 4 — Branding | [phase-4/](phase-4/) | 🔜 Upcoming |
| 5 — Packaging and release | [phase-5/](phase-5/) | 🔜 Upcoming |

---

## Deliverables (v1 target)

- Bootable x86_64 VM image
- Root filesystem tarball
- Release manifest and checksums
- This repo: notes, scripts, patches, branding, and release docs

---

## References

- LFS 13.0-systemd book: https://linuxfromscratch.org/lfs/view/stable-systemd/
- BLFS 13.0-systemd book: https://linuxfromscratch.org/blfs/view/stable-systemd/
- LFS errata: https://linuxfromscratch.org/lfs/errata/stable-systemd/
- LFS host requirements: https://linuxfromscratch.org/lfs/view/stable-systemd/chapter02/hostreqs.html
