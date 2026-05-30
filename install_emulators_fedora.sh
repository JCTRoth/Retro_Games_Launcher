#!/usr/bin/env bash
# Fedora emulator installation script for DOS_Launcher.

set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIOS_DIR="$PROJECT_DIR/BIOS"
BIOS_FILE="$BIOS_DIR/scph1001.bin"
DUCKSTATION_SETTINGS="$HOME/.var/app/org.duckstation.DuckStation/config/duckstation/settings.ini"
PS1_ROMS_DIR="$PROJECT_DIR/ROMs/PS1"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

dnf_package_exists() {
    dnf list --available "$1" >/dev/null 2>&1 || dnf list --installed "$1" >/dev/null 2>&1
}

dnf_package_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

append_available_package() {
    local -n target=$1
    local package_name=$2
    if dnf_package_exists "$package_name"; then
        target+=("$package_name")
    fi
}

append_first_available_package() {
    local -n target=$1
    shift
    local candidate
    for candidate in "$@"; do
        if dnf_package_exists "$candidate"; then
            target+=("$candidate")
            return 0
        fi
    done
    return 1
}

install_dnf_packages() {
    local packages=() to_install=() package_name

    echo 'Refreshing DNF metadata...'
    sudo dnf makecache

    append_available_package packages dosbox
    append_available_package packages mgba-qt
    append_first_available_package packages mupen64plus-ui-console mupen64plus || true
    append_available_package packages mupen64plus-data
    append_available_package packages mupen64plus-video-glide64mk2
    append_available_package packages mupen64plus-audio-sdl
    append_available_package packages mupen64plus-input-sdl
    append_available_package packages mupen64plus-rsp-hle
    append_available_package packages flatpak

    for package_name in "${packages[@]}"; do
        if dnf_package_installed "$package_name"; then
            echo "  ✓ $package_name already installed"
        else
            to_install+=("$package_name")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "Installing packages: ${to_install[*]}"
        sudo dnf install -y "${to_install[@]}"
    else
        echo 'All required DNF packages are already installed.'
    fi
}

setup_flatpak() {
    echo 'Configuring Flatpak...'
    if ! command_exists flatpak; then
        sudo dnf install -y flatpak
    fi

    if ! flatpak remotes | grep -q '^flathub'; then
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        echo '  ✓ Flathub remote added'
    else
        echo '  ✓ Flathub already configured'
    fi
}

install_flatpak_apps() {
    local app_id app_name
    local apps=(
        'org.duckstation.DuckStation:DuckStation'
        'net.pcsx2.PCSX2:PCSX2'
        'org.ppsspp.PPSSPP:PPSSPP'
    )

    echo 'Installing Flatpak emulators...'
    for app_entry in "${apps[@]}"; do
        IFS=':' read -r app_id app_name <<< "$app_entry"
        if flatpak info "$app_id" >/dev/null 2>&1; then
            echo "  ✓ $app_name already installed"
        else
            flatpak install -y flathub "$app_id"
            echo "  ✓ $app_name installed"
        fi
    done
}

configure_duckstation() {
    mkdir -p "$(dirname "$DUCKSTATION_SETTINGS")" "$BIOS_DIR"

    if [ ! -f "$DUCKSTATION_SETTINGS" ]; then
        cat > "$DUCKSTATION_SETTINGS" <<EOF
[BIOS]
SearchDirectory = $BIOS_DIR

[GameList]
RecursivePaths = $PS1_ROMS_DIR
EOF
    fi

    sed -i '/^\[BIOS\]/,/^\[/ { /^[[:space:]]*SearchDirectory[[:space:]]*=/d; /^[[:space:]]*Paths[[:space:]]*=/d; }' "$DUCKSTATION_SETTINGS" || true
    sed -i '/^\[GameList\]/,/^\[/ { /^[[:space:]]*RecursivePaths[[:space:]]*=/d; }' "$DUCKSTATION_SETTINGS" || true
    sed -i "/^\[BIOS\]/a SearchDirectory = $BIOS_DIR" "$DUCKSTATION_SETTINGS"
    sed -i "/^\[GameList\]/a RecursivePaths = $PS1_ROMS_DIR" "$DUCKSTATION_SETTINGS"

    if [ -f "$BIOS_FILE" ]; then
        echo "  ✓ PS1 BIOS found at $BIOS_FILE"
    else
        echo "  ! PS1 BIOS missing at $BIOS_FILE"
    fi
}

verify_installations() {
    echo 'Verifying installed emulator commands...'
    for check in dosbox mgba-qt mupen64plus; do
        if command_exists "$check"; then
            echo "  ✓ $check -> $(command -v "$check")"
        else
            echo "  ! $check not found in PATH"
        fi
    done
}

main() {
    if ! command_exists dnf; then
        echo 'This installer is intended for Fedora systems.' >&2
        exit 1
    fi

    echo '=== DOS_Launcher Fedora installer ==='
    echo "Project directory: $PROJECT_DIR"
    echo

    install_dnf_packages
    echo
    setup_flatpak
    echo
    install_flatpak_apps
    echo
    configure_duckstation
    echo
    verify_installations
    echo
    echo 'Run ./create_launchers.sh after placing games and ROMs in the project folders.'
}

main "$@"