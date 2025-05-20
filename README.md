# GPurgeX

A modular, cross-platform debloating and package management toolkit for Linux and BSD. GPurgeX is designed for versatility, automation, and extensibility—whether you’re a casual user, power user, or developer.

---

## 1. Overview

- **Purpose:** Remove unwanted desktop apps and system bloat, with full backup/restore, dry-run, and multi-manager support.
- **Supported Managers:** apt, dnf, pacman, zypper, apk, pkg, flatpak, snapd (easily extensible).
- **Modes:** Dry-run, interactive, unattended, parallel, and restore.
- **Smart:** Auto-detects desktop environment and package manager(s).

---

## 2. Quick Start

```sh
# Simulate (safe, no changes)
bash gpurgex.sh --dry-run

# Actually remove bloat (be careful!)
sudo bash gpurgex.sh

# Restore everything you removed
gpurgex.sh --restore
```

---

## 3. Modular Usage

### 3.1. Groups & Customization

- **Default groups:** GNOME, KDE, XFCE, Flatpak, Snap, etc.
- **Custom groups:** Add your own in `packages.json`.
- **Select group:**

```sh
gpurgex.sh --group kde --dry-run
gpurgex.sh --group flatpak --dual-mode --unattended
```

### 3.2. Custom Package Lists

- **Plain text:** One package per line.
- **JSON:** Add arrays to `packages.json`.
- **Usage:**

```sh
gpurgex.sh --file mylist.txt --dry-run
gpurgex.sh --file packages.json --group kde
```

---

## 4. Modes & Flags

| Flag            | Description                                              |
|-----------------|---------------------------------------------------------|
| `--dry-run, -d` | Simulate only, no changes                               |
| `--file, -f`    | Use custom package list (text or JSON)                  |
| `--group`       | Use a specific group from `packages.json`               |
| `--detect-all`  | Remove from all detected managers                       |
| `--unattended`  | No prompts, for automation                              |
| `--dual-mode`   | Parallel and interactive removal                        |
| `--restore`     | Restore all removed packages from backup                |
| `--interactive` | TUI checklist for package selection (needs whiptail)    |
| `--help, -h`    | Show help                                               |

---

## 5. Interactive & Automation

- **Interactive:**

```sh
gpurgex.sh --interactive
```
(Requires `whiptail`)

- **Unattended:**

```sh
gpurgex.sh --unattended --group gnome
```

- **Parallel:**

```sh
gpurgex.sh --dual-mode --group kde
```

---

## 6. Backup & Restore

- **Backup:** All removed packages are saved to `removed_packages_backup.txt`.
- **Restore:**

```sh
gpurgex.sh --restore
```
(Restores using the same package manager and group.)

---

## 7. Extending GPurgeX

### 7.1. Add a New Package Manager

1. Copy an existing module in `lib/` (e.g., `cp lib/pm-apt.sh lib/pm-new.sh`).
2. Implement the required functions:
   - `pm_check_installed`, `pm_remove_package`, `pm_remove_package_simulate`, `pm_autoremove`, `pm_autoremove_simulate`, `pm_clean`, `pm_clean_simulate`
3. Add detection logic in `gpurgex.sh`.

### 7.2. Add a New Group

- Edit `packages.json`:

```json
{
  "gnome": ["decibels", ...],
  "kde": ["kcalc", ...],
  "mygroup": ["foo", "bar"]
}
```

---

## 8. Example `packages.json`

```json
{
  "gnome": ["decibels", "gnome-calculator", ...],
  "kde": ["kcalc", "konsole", ...],
  "flatpak": ["org.gnome.Maps", ...],
  "snap": ["vlc", ...]
}
```

---

## 9. Troubleshooting

- **Missing a manager?** Add a script in `lib/` and detection in `gpurgex.sh`.
- **Restore not working?** Ensure backup exists and manager is supported.
- **Want a GUI?** Use `--interactive` or extend with your favorite TUI/GUI toolkit.
- **Need more speed?** Use `--dual-mode` for parallel removals.

---

## 10. License

MIT License. See [LICENSE](LICENSE).

---

## 11. Authors & Contributions

- Main author: [ODIN7h3C0d3r]
- Contributions welcome! Open an issue or PR.
