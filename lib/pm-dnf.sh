#!/bin/bash
# pm-dnf.sh - Package manager module for DNF (Fedora/RHEL)

pm_check_installed() {
    rpm -q "$1" &> /dev/null
}

pm_remove_package() {
    sudo dnf remove -y "$1"
}

pm_remove_package_simulate() {
    sudo dnf remove --assumeno "$1"
}

pm_autoremove() {
    sudo dnf autoremove -y
}

pm_autoremove_simulate() {
    sudo dnf autoremove --assumeno
}

pm_clean() {
    sudo dnf clean all
}

pm_clean_simulate() {
    echo "Simulating dnf clean all (no-op)"
}
