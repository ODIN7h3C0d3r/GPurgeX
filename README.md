# GPurgeX

GPurgeX is a modular, cross-distro debloating tool for Linux and BSD systems. It removes unwanted packages using your system's native package manager, with support for dry-run, logging, and customizable package lists in JSON format.

---

## Features

- **Cross-distro support:** Works with apt, dnf, pacman, zypper, apk, and FreeBSD pkg (easily extensible).
- **Modular design:** Each package manager has its own script in `lib/`.
- **JSON-driven:** Default and custom package lists are stored in `packages.json`.
- **Dry-run mode:** Simulate removals safely before making changes.
- **Logging:** All actions are logged to `/var/log/gnome-debloat.log`.
- **Custom package lists:** Use your own list with `--file`.
- **Auto-detection:** Detects your package manager automatically.

---

## Usage

```sh
# Simulate removals using the default GNOME package list
bash gpurgex.sh --dry-run

# Actually remove packages (be careful!)
sudo bash gpurgex.sh

# Use a custom package list (plain text or JSON)
bash gpurgex.sh --file mylist.txt --dry-run
bash gpurgex.sh --file packages.json --dry-run
```

### Options

- `--dry-run, -d`       Simulate removal without actually removing packages.
- `--file <path>, -f <path>` Use a file containing a list of packages (one per line, or a JSON array under `.gnome`).
- `--help, -h`            Display help message.

---

## How it Works

- **Default list:** Loaded from `packages.json` (the `.gnome` array).
- **Custom list:** If a file is provided, it is parsed as JSON (if `.json`), or as a plain text list.
- **Detection:** The script detects your package manager and loads the correct module from `lib/`.
- **Simulation:** In dry-run mode, no changes are made; commands are simulated.
- **Logging:** All real actions are logged for review.

---

## Extending GPurgeX

- **Add a new package manager:**
  1. Create a new script in `lib/` (e.g., `pm-foo.sh`).
  2. Implement the required functions: `pm_check_installed`, `pm_remove_package`, `pm_remove_package_simulate`, `pm_autoremove`, `pm_autoremove_simulate`, `pm_clean`, `pm_clean_simulate`.
  3. Add detection logic in `gpurgex.sh`.

- **Add more package groups:**
  - Add new arrays to `packages.json` (e.g., `kde`, `xfce`).
  - Adjust the script to select the group you want.

---

## Example `packages.json`

```json
{
  "gnome": [
    "decibels",
    "gnome-calculator",
    "gnome-calendar"
    // ...
  ]
}
```

---

## What Could Be Added?

- **Interactive group selection:** Let users pick a group (e.g., GNOME, KDE, XFCE) at runtime.
- **Backup/restore:** Optionally back up package lists or system state before removal.
- **Parallel removals:** Speed up removals on systems with many packages.
- **GUI frontend:** A simple graphical interface for less technical users.
- **Better error handling:** More robust checks and user feedback.
- **Unattended mode:** For scripting and automation.
- **Internationalization:** Support for multiple languages.
- **More package managers:** Add support for additional Linux/BSD distros.
- **Package reinstall/restore:** Option to reinstall removed packages from a log.

---

## License

MIT License. See [LICENSE](LICENSE).

---

## Authors & Contributions

- Main author: [ODIN7h3C0d3r]
- Contributions welcome! Open an issue or PR.
