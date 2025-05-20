# GPurgeX

---

## For Everyone (Normal User)

**GPurgeX** is your all-in-one, safe, and powerful tool to remove unwanted desktop apps and bloat from your Linux or BSD system. It works with all major package managers, supports dry-run simulation, and can even restore what you remove!

- **No more bloat:** Remove GNOME, KDE, Flatpak, Snap, and more.
- **Safe:** Try a dry-run first, see what will be removed.
- **Easy restore:** Accidentally removed something? Restore it with one command.
- **Smart:** Detects your desktop and package manager automatically.
- **Interactive:** Pick what you want to remove with a beautiful menu (if `whiptail` is installed).
- **Unattended:** Automate everything for scripts or mass deployments.


### Quick Start

```sh
# Simulate what would be removed (safe!)
bash gpurgex.sh --dry-run

# Actually remove bloat (be careful!)
sudo bash gpurgex.sh

# Restore everything you removed
gpurgex.sh --restore
```

---

## For Power Users

- **Custom groups:** Add your own package groups in `packages.json` (e.g., KDE, XFCE, custom apps).
- **Parallel removal:** Use `--dual-mode` for fast, parallel uninstalls.
- **Unattended mode:** Use `--unattended` for zero prompts.
- **Interactive selection:** Use `--interactive` for a TUI checklist.
- **Full logging:** All actions are logged to `/var/log/gnome-debloat.log`.
- **Backup/restore:** All removed packages are backed up for one-command restore.
- **Multi-manager:** Use `--detect-all` to remove bloat from all detected package managers (apt, dnf, pacman, zypper, apk, pkg, flatpak, snapd).


### Example Power Usage

```sh
# Remove all GNOME and Flatpak bloat, unattended, and in parallel
gpurgex.sh --group gnome --dual-mode --unattended
gpurgex.sh --group flatpak --dual-mode --unattended

# Remove from all detected managers
gpurgex.sh --detect-all --unattended
```

---

## For Developers

- **Modular:** Add new package managers by dropping a script in `lib/pm-*.sh`.
- **JSON-driven:** Add/remove package groups in `packages.json`.
- **Hooks:** All core logic is in functions, easy to extend.
- **Restore logic:** Real package reinstall for all supported managers.
- **Error handling:** Robust, with traps and clear logs.
- **Beautiful CLI:** Interactive TUI with `whiptail` (or extend with `gum`, `dialog`, etc).
- **Auto-detect DE:** Detects GNOME, KDE, XFCE, LXDE, MATE, Cinnamon, etc.
- **Flags:**
  - `--dry-run, -d`: Simulate only
  - `--file, -f`: Use custom package list
  - `--group`: Use a specific group from `packages.json`
  - `--detect-all`: Remove from all detected managers
  - `--unattended`: No prompts
  - `--dual-mode`: Parallel and interactive
  - `--restore`: Restore from backup
  - `--interactive`: TUI checklist


### Example Developer Extension

```sh
# Add a new package manager
cp lib/pm-apt.sh lib/pm-homebrew.sh
# Edit functions for Homebrew logic
# Add detection in gpurgex.sh
```

---

## How it Works

- **Auto-detects** your desktop and package manager.
- **Loads** the right package group from `packages.json`.
- **Interactive** or unattended removal, with dry-run support.
- **Backs up** all removed packages for easy restore.
- **Parallel** removal for speed (dual-mode).
- **Logs** everything for review and troubleshooting.

---

## Example `packages.json`

```json
{
  "gnome": ["decibels", "gnome-calculator", ...],
  "kde": ["kcalc", "konsole", ...],
  "flatpak": ["org.gnome.Maps", ...],
  "snap": ["vlc", ...]
}
```

---

## Troubleshooting & Tips

- **Missing a package manager?** Add a new script in `lib/` and detection logic in `gpurgex.sh`.
- **Want a GUI?** Use `--interactive` or extend with your favorite TUI/GUI toolkit.
- **Restore not working?** Make sure your backup file exists and your package manager is supported.
- **Need more speed?** Use `--dual-mode` for parallel removals.

---

## License

MIT License. See [LICENSE](LICENSE).

---

## Authors & Contributions

- Main author: [Your Name]
- Contributions welcome! Open an issue or PR.
