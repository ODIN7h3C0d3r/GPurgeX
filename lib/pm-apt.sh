#!/bin/bash
# pm-apt.sh - Package manager module for APT (Debian/Ubuntu)

pm_check_installed() {
    dpkg -s "$1" &> /dev/null
}

pm_remove_package() {
    sudo apt remove --purge -y "$1"
}

pm_remove_package_simulate() {
    sudo apt remove --purge --simulate -y "$1"
}

pm_autoremove() {
    sudo apt autoremove -y
}

pm_autoremove_simulate() {
    sudo apt autoremove --simulate -y
}

pm_clean() {
    sudo apt clean
}

pm_clean_simulate() {
    sudo apt clean --simulate
}
