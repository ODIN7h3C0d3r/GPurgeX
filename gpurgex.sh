#!/bin/bash

# GPurgeX-GNOME Debloating Script
# -------------------------------
# This script attempts to remove GNOME applications.
# It supports a dry run mode and can read package lists from a file.
# USE WITH CAUTION! Review the package list and use dry run first.
# It's highly recommended to back up your system before proceeding.

# --- Configuration ---
PACKAGES_JSON="packages.json"
DEFAULT_PACKAGES_TO_REMOVE=()

fetch_default_packages() {
    if command -v jq &>/dev/null; then
        DEFAULT_PACKAGES_TO_REMOVE=( $(jq -r '.gnome[]' "$PACKAGES_JSON") )
    else
        echo "Error: 'jq' is required to parse $PACKAGES_JSON. Please install jq." >&2
        exit 1
    fi
}

LOG_FILE="/var/log/gnome-debloat.log" # Ensure this directory is writable by the script runner or run with sudo

# --- Script Variables ---
DRY_RUN=0
PACKAGE_FILE=""
PACKAGES_TO_REMOVE=()
PM_MODULE=""
PM_NAME=""
GROUP_NAME="gnome"
DETECT_ALL=0
UNATTENDED=0
DUAL_MODE=0
BACKUP_FILE="removed_packages_backup.txt"
INTERACTIVE=0

# --- Desktop Environment Detection ---
detect_desktop_environment() {
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        case "$XDG_CURRENT_DESKTOP" in
            *GNOME*) GROUP_NAME="gnome" ;;
            *KDE*) GROUP_NAME="kde" ;;
            *XFCE*) GROUP_NAME="xfce" ;;
            *LXDE*) GROUP_NAME="lxde" ;;
            *LXQt*) GROUP_NAME="lxqt" ;;
            *MATE*) GROUP_NAME="mate" ;;
            *Cinnamon*) GROUP_NAME="cinnamon" ;;
            *) GROUP_NAME="gnome" ;;
        esac
        echo "Detected desktop environment: $XDG_CURRENT_DESKTOP (using group: $GROUP_NAME)"
    else
        # Try to detect from running processes if XDG_CURRENT_DESKTOP is not set
        if pgrep -x gnome-shell >/dev/null; then
            GROUP_NAME="gnome"
            echo "Detected GNOME desktop environment (via process)."
        elif pgrep -x plasmashell >/dev/null; then
            GROUP_NAME="kde"
            echo "Detected KDE desktop environment (via process)."
        elif pgrep -x xfce4-session >/dev/null; then
            GROUP_NAME="xfce"
            echo "Detected XFCE desktop environment (via process)."
        elif pgrep -x lxsession >/dev/null; then
            GROUP_NAME="lxde"
            echo "Detected LXDE desktop environment (via process)."
        elif pgrep -x mate-session >/dev/null; then
            GROUP_NAME="mate"
            echo "Detected MATE desktop environment (via process)."
        elif pgrep -x cinnamon-session >/dev/null; then
            GROUP_NAME="cinnamon"
            echo "Detected Cinnamon desktop environment (via process)."
        else
            GROUP_NAME="gnome"
            echo "Could not auto-detect desktop environment, defaulting to GNOME."
        fi
    fi
}

# --- Backup/Restore ---
backup_packages() {
    printf "%s\n" "${PACKAGES_TO_REMOVE[@]}" > "$BACKUP_FILE"
    echo "Backup of packages to be removed saved to $BACKUP_FILE."
}

restore_packages() {
    if [ -f "$BACKUP_FILE" ]; then
        mapfile -t RESTORE_LIST < "$BACKUP_FILE"
        for pkg in "${RESTORE_LIST[@]}"; do
            if pm_check_installed "$pkg"; then
                echo "$pkg already installed."
            else
                echo "Reinstalling $pkg..."
                if [ "$PM_NAME" = "apt" ]; then
                    sudo apt install -y "$pkg"
                elif [ "$PM_NAME" = "dnf" ]; then
                    sudo dnf install -y "$pkg"
                elif [ "$PM_NAME" = "pacman" ]; then
                    sudo pacman -S --noconfirm "$pkg"
                elif [ "$PM_NAME" = "zypper" ]; then
                    sudo zypper --non-interactive install "$pkg"
                elif [ "$PM_NAME" = "apk" ]; then
                    sudo apk add "$pkg"
                elif [ "$PM_NAME" = "pkg" ]; then
                    sudo pkg install -y "$pkg"
                elif [ "$PM_NAME" = "flatpak" ]; then
                    sudo flatpak install -y "$pkg"
                elif [ "$PM_NAME" = "snapd" ]; then
                    sudo snap install "$pkg"
                else
                    echo "Restore not supported for package manager: $PM_NAME"
                fi
            fi
        done
    else
        echo "No backup file found to restore from."
    fi
}

# --- Interactive CLI (using whiptail if available) ---
interactive_package_selection() {
    if command -v whiptail &>/dev/null; then
        local options=()
        for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
            options+=("$pkg" "" ON)
        done
        local selected
        selected=$(whiptail --title "Select packages to remove" --checklist "Choose packages (use space to select):" 20 78 15 "${options[@]}" 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
            PACKAGES_TO_REMOVE=()
            for pkg in $selected; do
                pkg_cleaned=$(echo $pkg | tr -d '"')
                PACKAGES_TO_REMOVE+=("$pkg_cleaned")
            done
        else
            echo "No packages selected. Exiting."
            exit 1
        fi
    else
        echo "whiptail not found, skipping interactive selection."
    fi
}

# --- Parallel Removal ---
parallel_remove_packages() {
    local pids=()
    for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
        (
            if pm_check_installed "$pkg"; then
                pm_remove_package "$pkg"
                if [ $? -eq 0 ]; then
                    echo "$pkg successfully removed."
                    log_message "Removed: $pkg"
                else
                    echo "Failed to remove $pkg. An error occurred or it was already removed by a dependency."
                    log_message "Failed to remove: $pkg"
                fi
            else
                echo "$pkg is not installed or already removed."
                log_message "Not installed or already removed: $pkg"
            fi
        ) &
        pids+=("$!")
    done
    local fail=0
    for pid in "${pids[@]}"; do
        wait "$pid" || fail=1
    done
    if [ $fail -ne 0 ]; then
        echo "Some removals failed. Check the log for details."
    fi
}

# --- Detect Package Manager ---
detect_package_manager() {
    local detected=0
    local managers=()
    if command -v apt &>/dev/null; then
        managers+=("apt")
    fi
    if command -v dnf &>/dev/null; then
        managers+=("dnf")
    fi
    if command -v pacman &>/dev/null; then
        managers+=("pacman")
    fi
    if command -v zypper &>/dev/null; then
        managers+=("zypper")
    fi
    if command -v apk &>/dev/null; then
        managers+=("apk")
    fi
    if command -v pkg &>/dev/null; then
        managers+=("pkg")
    fi
    if command -v flatpak &>/dev/null; then
        managers+=("flatpak")
    fi
    if command -v snap &>/dev/null; then
        managers+=("snapd")
    fi
    if [ $DETECT_ALL -eq 1 ]; then
        echo "Detected package managers: ${managers[*]}"
        for pm in "${managers[@]}"; do
            echo "- $pm"
        done
        read -r -p "Remove packages from all detected managers? (yes/NO): " all_confirm
        if [[ "$all_confirm" == "yes" ]]; then
            for pm in "${managers[@]}"; do
                PM_NAME="$pm"
                PM_MODULE="lib/pm-$pm.sh"
                echo "\n--- Removing from $PM_NAME ---"
                . "$PM_MODULE"
                run_removal
            done
            exit 0
        else
            echo "Operation cancelled."
            exit 0
        fi
    else
        if [ ${#managers[@]} -eq 0 ]; then
            echo "Error: No supported package manager found." >&2
            exit 1
        fi
        PM_NAME="${managers[0]}"
        PM_MODULE="lib/pm-${PM_NAME}.sh"
        echo "Detected package manager: $PM_NAME"
    fi
}

# --- Functions ---
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --dry-run, -d         Simulate removal without actually removing packages."
    echo "  --file <path>, -f     Use a file containing a list of packages (one per line, or JSON array)."
    echo "  --help, -h            Display this help message."
    echo "  --group <name>        Use a specific group from packages.json (e.g., gnome, kde, flatpak, snap)."
    echo "  --detect-all          Show all detected package managers and offer to remove from all."
    echo "  --unattended          Run in unattended mode (no prompts)."
    echo "  --dual-mode           Run in both interactive and unattended/parallel mode."
    echo "  --restore             Restore previously removed packages from backup."
    echo "  --interactive         Use interactive CLI for package selection (requires whiptail)."
    echo ""
    echo "If no package file is specified, a default list of packages will be used."
    echo "Desktop environment is auto-detected if possible."
}

log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | sudo tee -a "$LOG_FILE" > /dev/null
}

run_removal() {
    echo ""
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Simulating package removal..."
        for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
            echo "---------------------------------------------"
            pm_remove_package_simulate "$pkg"
        done
    elif [ "$DUAL_MODE" == "1" ]; then
        echo "Running parallel removal in dual-mode..."
        parallel_remove_packages
    else
        echo "Proceeding with package removal..."
        echo "You may be prompted for your sudo password multiple times if not already cached."
        for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
            echo "---------------------------------------------"
            if pm_check_installed "$pkg"; then
                echo "Targeting $pkg for removal..."
                pm_remove_package "$pkg"
                if [ $? -eq 0 ]; then
                    echo "$pkg successfully removed."
                    log_message "Removed: $pkg"
                else
                    echo "Failed to remove $pkg. An error occurred or it was already removed by a dependency."
                    log_message "Failed to remove: $pkg"
                fi
            else
                echo "$pkg is not installed or already removed."
                log_message "Not installed or already removed: $pkg"
            fi
        done
    fi
    echo "---------------------------------------------"
    echo ""
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Simulating removal of unused dependencies..."
        pm_autoremove_simulate
        echo "Simulating cleaning of package cache..."
        pm_clean_simulate
    else
        echo "Attempting to remove unused dependencies..."
        pm_autoremove
        log_message "Ran autoremove."
        echo "Cleaning up local repository of retrieved package files..."
        pm_clean
        log_message "Ran clean."
    fi
    echo ""
    echo "Debloating process finished."
    if [ "$DRY_RUN" -eq 0 ]; then
        log_message "--- Debloat session finished ---"
        echo "Log saved to $LOG_FILE"
        echo "It's recommended to reboot your system."
    else
        echo "*** DRY RUN COMPLETED ***"
    fi
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=1; shift ;;
        -f|--file) PACKAGE_FILE="$2"; shift; shift ;;
        -h|--help) print_usage; exit 0 ;;
        --group) GROUP_NAME="$2"; shift; shift ;;
        --detect-all) DETECT_ALL=1; shift ;;
        --unattended) UNATTENDED=1; shift ;;
        --dual-mode) DUAL_MODE=1; shift ;;
        --restore) RESTORE=1; shift ;;
        --interactive) INTERACTIVE=1; shift ;;
        *) echo "Unknown parameter passed: $1"; print_usage; exit 1 ;;
    esac
done

# --- Determine Package List ---
if [[ -n "$PACKAGE_FILE" ]]; then
    if [[ -f "$PACKAGE_FILE" ]]; then
        if [[ "$PACKAGE_FILE" == *.json ]]; then
            if command -v jq &>/dev/null; then
                mapfile -t PACKAGES_TO_REMOVE < <(jq -r ".${GROUP_NAME}[]" "$PACKAGE_FILE")
            else
                echo "Error: 'jq' is required to parse $PACKAGE_FILE. Please install jq." >&2
                exit 1
            fi
        else
            mapfile -t PACKAGES_TO_REMOVE < <(grep -vE '^\s*#|^\s*$' "$PACKAGE_FILE")
        fi
        if [ ${#PACKAGES_TO_REMOVE[@]} -eq 0 ]; then
            echo "Error: Package file '$PACKAGE_FILE' is empty or only contains comments."
            exit 1
        fi
        echo "Using package list from: $PACKAGE_FILE (group: $GROUP_NAME)"
    else
        echo "Error: Package file '$PACKAGE_FILE' not found."
        exit 1
    fi
else
    echo "Using default internal package list from $PACKAGES_JSON (group: $GROUP_NAME)."
    if command -v jq &>/dev/null; then
        mapfile -t DEFAULT_PACKAGES_TO_REMOVE < <(jq -r ".${GROUP_NAME}[]" "$PACKAGES_JSON")
    else
        echo "Error: 'jq' is required to parse $PACKAGES_JSON. Please install jq." >&2
        exit 1
    fi
    PACKAGES_TO_REMOVE=("${DEFAULT_PACKAGES_TO_REMOVE[@]}")
fi

# --- Main Script ---
if [ "$RESTORE" == "1" ]; then
    detect_package_manager
    . "$PM_MODULE"
    restore_packages
    exit 0
fi

detect_desktop_environment

echo ""
echo "GNOME Debloating Script"
echo "-----------------------"

if [ "$DRY_RUN" -eq 1 ]; then
    echo "*** DRY RUN MODE ENABLED - NO PACKAGES WILL BE REMOVED ***"
fi

echo ""
echo "The following packages will be targeted:"
for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    echo "- $pkg"
done
echo ""

if [ "$INTERACTIVE" == "1" ]; then
    interactive_package_selection
fi

if [ "$UNATTENDED" == "1" ]; then
    DRY_RUN=0
    confirmation="yes"
else
    if [ "$DRY_RUN" -eq 0 ]; then
        read -r -p "Are you sure you want to proceed with removing these packages? (yes/NO): " confirmation
    fi
fi

if [ "$confirmation" != "yes" ] && [ "$DRY_RUN" -eq 0 ]; then
    echo "Operation cancelled by the user."
    exit 0
fi

backup_packages

echo "Ensuring log file exists and is writable..."
sudo touch "$LOG_FILE"
sudo chown "$(whoami)" "$LOG_FILE" # Or adjust permissions as needed
log_message "--- Debloat session started ---"

detect_package_manager
# shellcheck source=/dev/null
. "$PM_MODULE"
run_removal
exit 0

# Improved error handling: trap errors and print a message
trap 'echo "An error occurred. Exiting."; exit 1' ERR

if [ "$DUAL_MODE" == "1" ]; then
    echo "Running in dual-mode: interactive and unattended."
    INTERACTIVE=1
    UNATTENDED=1
fi