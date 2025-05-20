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

# --- Detect Package Manager ---
detect_package_manager() {
    if command -v apt &>/dev/null; then
        PM_MODULE="lib/pm-apt.sh"
        PM_NAME="apt"
    elif command -v dnf &>/dev/null; then
        PM_MODULE="lib/pm-dnf.sh"
        PM_NAME="dnf"
    elif command -v pacman &>/dev/null; then
        PM_MODULE="lib/pm-pacman.sh"
        PM_NAME="pacman"
    elif command -v zypper &>/dev/null; then
        PM_MODULE="lib/pm-zypper.sh"
        PM_NAME="zypper"
    elif command -v apk &>/dev/null; then
        PM_MODULE="lib/pm-apk.sh"
        PM_NAME="apk"
    elif command -v pkg &>/dev/null; then
        PM_MODULE="lib/pm-pkg.sh"
        PM_NAME="pkg"
    else
        echo "Error: No supported package manager found." >&2
        exit 1
    fi
    echo "Detected package manager: $PM_NAME"
}

# --- Functions ---
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --dry-run, -d       Simulate removal without actually removing packages."
    echo "  --file <path>, -f <path> Use a file containing a list of packages (one per line)."
    echo "  --help, -h            Display this help message."
    echo ""
    echo "If no package file is specified, a default list of packages will be used."
}

log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | sudo tee -a "$LOG_FILE" > /dev/null
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=1; shift ;;
        -f|--file) PACKAGE_FILE="$2"; shift; shift ;;
        -h|--help) print_usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; print_usage; exit 1 ;;
    esac
done

# --- Determine Package List ---
if [[ -n "$PACKAGE_FILE" ]]; then
    if [[ -f "$PACKAGE_FILE" ]]; then
        # If the file is a JSON file, extract the gnome array using jq
        if [[ "$PACKAGE_FILE" == *.json ]]; then
            if command -v jq &>/dev/null; then
                mapfile -t PACKAGES_TO_REMOVE < <(jq -r '.gnome[]' "$PACKAGE_FILE")
            else
                echo "Error: 'jq' is required to parse $PACKAGE_FILE. Please install jq." >&2
                exit 1
            fi
        else
            mapfile -t PACKAGES_TO_REMOVE < <(grep -vE '^\s*#|^\s*$' "$PACKAGE_FILE") # Read file, ignore comments and empty lines
        fi
        if [ ${#PACKAGES_TO_REMOVE[@]} -eq 0 ]; then
            echo "Error: Package file '$PACKAGE_FILE' is empty or only contains comments."
            exit 1
        fi
        echo "Using package list from: $PACKAGE_FILE"
    else
        echo "Error: Package file '$PACKAGE_FILE' not found."
        exit 1
    fi
else
    echo "Using default internal package list from $PACKAGES_JSON."
    fetch_default_packages
    PACKAGES_TO_REMOVE=("${DEFAULT_PACKAGES_TO_REMOVE[@]}")
fi

# --- Main Script ---
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

if [ "$DRY_RUN" -eq 0 ]; then
    read -r -p "Are you sure you want to proceed with removing these packages? (yes/NO): " confirmation
    if [[ "$confirmation" != "yes" ]]; then
        echo "Operation cancelled by the user."
        exit 0
    fi
    echo "Ensuring log file exists and is writable..."
    sudo touch "$LOG_FILE"
    sudo chown "$(whoami)" "$LOG_FILE" # Or adjust permissions as needed
    log_message "--- Debloat session started ---"
fi

detect_package_manager
# shellcheck source=/dev/null
. "$PM_MODULE"

echo ""
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Simulating package removal..."
else
    echo "Proceeding with package removal..."
    echo "You may be prompted for your sudo password multiple times if not already cached."
fi
echo ""

# Attempt to remove each package
for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    echo "---------------------------------------------"
    if pm_check_installed "$pkg"; then
        echo "Targeting $pkg for removal..."
        if [ "$DRY_RUN" -eq 1 ]; then
            pm_remove_package_simulate "$pkg"
        else
            pm_remove_package "$pkg"
            if [ $? -eq 0 ]; then
                echo "$pkg successfully removed."
                log_message "Removed: $pkg"
            else
                echo "Failed to remove $pkg. An error occurred or it was already removed by a dependency."
                log_message "Failed to remove: $pkg"
            fi
        fi
    else
        echo "$pkg is not installed or already removed."
        if [ "$DRY_RUN" -eq 0 ]; then
            log_message "Not installed or already removed: $pkg"
        fi
    fi
done
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

exit 0