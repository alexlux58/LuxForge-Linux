# Phase 5 — Packaging and Release

> Export LuxForge Linux v1 as distributable artifacts.

This phase produces the final deliverables: a VM image, a root filesystem tarball, a release manifest, and checksums.

---

## Deliverables

| Artifact | Description |
|---|---|
| `luxforge-aurelux-v1.qcow2` | Bootable x86_64 VM image |
| `luxforge-aurelux-v1-rootfs.tar.xz` | Root filesystem tarball |
| `MANIFEST.txt` | List of all installed packages and versions |
| `SHA256SUMS` | Checksums for all release artifacts |
| Build repo | This repo with notes, scripts, patches, and branding |

---

## Steps

1. Clean up the LFS system (remove build artifacts, temporary files)
2. Export the root filesystem as a compressed tarball
3. Export or convert the VM disk image
4. Generate the package manifest from the installed system
5. Hash all artifacts and write `SHA256SUMS`
6. Tag the release in this repo

---

## Notes

This section will be filled in as Phase 5 progresses.

---

→ Previous: [Phase 4 — Branding](../phase-4/)
