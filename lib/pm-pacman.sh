#!/bin/bash
# pm-pacman.sh - Package manager module for Pacman (Arch Linux)

pm_check_installed() {
    pacman -Q "$1" &> /dev/null
}

pm_remove_package() {
    sudo pacman -Rns --noconfirm "$1"
}

pm_remove_package_simulate() {
    echo "Simulating: sudo pacman -Rns --noconfirm $1"
}

pm_autoremove() {
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm
}

pm_autoremove_simulate() {
    echo "Simulating: sudo pacman -Rns \\$(pacman -Qdtq) --noconfirm"
}

pm_clean() {
    sudo pacman -Sc --noconfirm
}

pm_clean_simulate() {
    echo "Simulating: sudo pacman -Sc --noconfirm"
}
