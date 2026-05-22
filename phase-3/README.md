# Phase 3 — BLFS Server Layer

> Extend LuxForge Linux with a minimal but practical server package set.

This phase uses the [BLFS 13.0-systemd book](https://linuxfromscratch.org/blfs/view/stable-systemd/) to add the software needed to make the base system usable as a server. Every package is compiled from source and installed on top of the Phase 2 base system.

---

## Target package set

| Package | Purpose |
|---|---|
| OpenSSH | Remote access |
| sudo | Privilege escalation for non-root users |
| curl | HTTP/HTTPS client and scripting tool |
| git | Version control |
| CA certificates | TLS certificate verification |
| vim or neovim | Terminal text editor |
| tmux | Terminal multiplexer |
| rsync | File synchronization and transfer |

---

## Approach

BLFS does not prescribe a single path — you pick only the packages you need. Each BLFS page lists its own dependencies, and those may require their own BLFS dependencies. Read each page carefully before starting a package to avoid missing prerequisites.

---

## Notes

This section will be filled in as Phase 3 progresses.

---

→ Previous: [Phase 2 — Base OS](../phase-2/) | Next: [Phase 4 — Branding](../phase-4/)
