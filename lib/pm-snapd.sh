#!/bin/bash
# pm-snapd.sh - Package manager module for Snapd

pm_check_installed() {
    snap list | awk '{print $1}' | grep -q "^$1$"
}

pm_remove_package() {
    sudo snap remove "$1"
}

pm_remove_package_simulate() {
    echo "Simulating: sudo snap remove $1"
}

pm_autoremove() {
    echo "Snapd does not have a direct autoremove command."
}

pm_autoremove_simulate() {
    echo "Simulating: Snapd does not have a direct autoremove command."
}

pm_clean() {
    sudo snap set system refresh.retain=2
    sudo snap remove --purge $(snap list --all | awk '/disabled/{print $1, $2}' | while read snapname version; do echo "$snapname --revision=$version"; done)
}

pm_clean_simulate() {
    echo "Simulating: sudo snap set system refresh.retain=2 && sudo snap remove --purge <old-snaps>"
}
