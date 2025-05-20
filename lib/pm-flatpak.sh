#!/bin/bash
# pm-flatpak.sh - Package manager module for Flatpak

pm_check_installed() {
    flatpak list --app | awk '{print $1}' | grep -q "^$1$"
}

pm_remove_package() {
    sudo flatpak uninstall -y "$1"
}

pm_remove_package_simulate() {
    echo "Simulating: sudo flatpak uninstall -y $1"
}

pm_autoremove() {
    sudo flatpak uninstall --unused -y
}

pm_autoremove_simulate() {
    echo "Simulating: sudo flatpak uninstall --unused -y"
}

pm_clean() {
    echo "Flatpak does not require explicit cache cleaning."
}

pm_clean_simulate() {
    echo "Simulating: Flatpak does not require explicit cache cleaning."
}
