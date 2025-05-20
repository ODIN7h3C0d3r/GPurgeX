#!/bin/bash
# pm-zypper.sh - Package manager module for Zypper (openSUSE)

pm_check_installed() {
    rpm -q "$1" &> /dev/null
}

pm_remove_package() {
    sudo zypper --non-interactive remove "$1"
}

pm_remove_package_simulate() {
    sudo zypper --dry-run remove "$1"
}

pm_autoremove() {
    sudo zypper --non-interactive remove --clean-deps $(zypper packages --unneeded | awk 'NR>2 {print $3}')
}

pm_autoremove_simulate() {
    echo "Simulating: sudo zypper --dry-run remove --clean-deps $(zypper packages --unneeded | awk 'NR>2 {print $3}')"
}

pm_clean() {
    sudo zypper clean --all
}

pm_clean_simulate() {
    echo "Simulating: sudo zypper clean --all"
}
