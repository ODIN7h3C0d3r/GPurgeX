#!/bin/bash
# pm-pkg.sh - Package manager module for FreeBSD pkg

pm_check_installed() {
    pkg info "$1" > /dev/null 2>&1
}

pm_remove_package() {
    sudo pkg delete -y "$1"
}

pm_remove_package_simulate() {
    echo "Simulating: sudo pkg delete -n $1"
    sudo pkg delete -n "$1"
}

pm_autoremove() {
    sudo pkg autoremove -y
}

pm_autoremove_simulate() {
    echo "Simulating: sudo pkg autoremove -n"
    sudo pkg autoremove -n
}

pm_clean() {
    sudo pkg clean -y
}

pm_clean_simulate() {
    echo "Simulating: sudo pkg clean -n"
    sudo pkg clean -n
}
