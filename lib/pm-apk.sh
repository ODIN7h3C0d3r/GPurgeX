#!/bin/bash
# pm-apk.sh - Package manager module for Alpine Linux (apk)

pm_check_installed() {
    apk info -e "$1" > /dev/null 2>&1
}

pm_remove_package() {
    sudo apk del "$1"
}

pm_remove_package_simulate() {
    echo "Simulating: sudo apk del $1"
}

pm_autoremove() {
    echo "Alpine's apk does not have a direct autoremove command."
}

pm_autoremove_simulate() {
    echo "Simulating: Alpine's apk does not have a direct autoremove command."
}

pm_clean() {
    sudo apk cache clean
}

pm_clean_simulate() {
    echo "Simulating: sudo apk cache clean"
}
