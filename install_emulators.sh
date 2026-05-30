#!/usr/bin/env bash
# Debian/Ubuntu emulator installation script for DOS_Launcher.

set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIOS_DIR="$PROJECT_DIR/BIOS"
BIOS_FILE="$BIOS_DIR/scph1001.bin"
DUCKSTATION_SETTINGS="$HOME/.var/app/org.duckstation.DuckStation/config/duckstation/settings.ini"
DUCKSTATION_BIOS_DIR="$HOME/.var/app/org.duckstation.DuckStation/config/duckstation/bios"
PS1_ROMS_DIR="$PROJECT_DIR/ROMs/PS1"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

apt_package_exists() {
    apt-cache show "$1" >/dev/null 2>&1
}

apt_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

append_available_package() {
    local -n target=$1
    local package_name=$2
    if apt_package_exists "$package_name"; then
        target+=("$package_name")
    fi
}

append_first_available_package() {
    local -n target=$1
    shift
    local candidate
    for candidate in "$@"; do
        if apt_package_exists "$candidate"; then
            target+=("$candidate")
            return 0
        fi
    done
    return 1
}

install_apt_packages() {
    local packages=() to_install=() package_name

    echo 'Updating APT metadata...'
    sudo apt update

    append_available_package packages dosbox
    append_available_package packages mgba-qt
    append_first_available_package packages mupen64plus-ui-console mupen64plus || true
    append_available_package packages mupen64plus-data
    append_available_package packages mupen64plus-video-glide64mk2
    append_available_package packages mupen64plus-audio-sdl
    append_available_package packages mupen64plus-input-sdl
    append_available_package packages mupen64plus-rsp-hle
    append_available_package packages flatpak

    echo 'Checking Debian/Ubuntu packages...'
    for package_name in "${packages[@]}"; do
        if apt_package_installed "$package_name"; then
            echo "  ✓ $package_name already installed"
        else
            to_install+=("$package_name")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "Installing packages: ${to_install[*]}"
        sudo apt install -y "${to_install[@]}"
    else
        echo 'All required APT packages are already installed.'
    fi
}

setup_flatpak() {
    echo 'Configuring Flatpak...'
    if ! command_exists flatpak; then
        echo '  Flatpak is missing after package install; installing directly.'
        sudo apt install -y flatpak
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

apply_flatpak_overrides() {
    local app_id
    echo 'Granting project-folder access to Flatpak emulators...'
    for app_id in org.duckstation.DuckStation net.pcsx2.PCSX2 org.ppsspp.PPSSPP; do
        flatpak override --user --filesystem="$PROJECT_DIR" "$app_id"
        echo "  ✓ $app_id can access $PROJECT_DIR"
    done
}

create_default_duckstation_config() {
    cat > "$DUCKSTATION_SETTINGS" <<EOF
[Main]
ConfirmExit = false
SaveStateOnExit = false
StartPaused = false
PauseOnFocusLoss = false

[Display]
VSync = true
MaxFPS = 60

[Audio]
OutputLatency = 50
StretchMode = 1

[BIOS]
SearchDirectory = $BIOS_DIR

[Graphics]
ResolutionScale = 2
TrueColor = true
TextureFilter = 1
PGXP = true
PGXPVertexCache = true

[MemoryCards]
Card1Type = PerGameTitle
Card2Type = PerGameTitle

[GameList]
RecursivePaths = $PS1_ROMS_DIR
EOF
}

ensure_duckstation_paths_configured() {
    mkdir -p "$(dirname "$DUCKSTATION_SETTINGS")"

    if [ ! -f "$DUCKSTATION_SETTINGS" ]; then
        create_default_duckstation_config
    fi

    if ! grep -q '^\[BIOS\]' "$DUCKSTATION_SETTINGS"; then
        printf '\n[BIOS]\n' >> "$DUCKSTATION_SETTINGS"
    fi
    if ! grep -q '^\[GameList\]' "$DUCKSTATION_SETTINGS"; then
        printf '\n[GameList]\n' >> "$DUCKSTATION_SETTINGS"
    fi

    sed -i '/^\[BIOS\]/,/^\[/ { /^[[:space:]]*SearchDirectory[[:space:]]*=/d; /^[[:space:]]*Paths[[:space:]]*=/d; }' "$DUCKSTATION_SETTINGS" || true
    sed -i '/^\[GameList\]/,/^\[/ { /^[[:space:]]*RecursivePaths[[:space:]]*=/d; }' "$DUCKSTATION_SETTINGS" || true
    sed -i "/^\[BIOS\]/a SearchDirectory = $BIOS_DIR" "$DUCKSTATION_SETTINGS"
    sed -i "/^\[GameList\]/a RecursivePaths = $PS1_ROMS_DIR" "$DUCKSTATION_SETTINGS"

    echo "  ✓ DuckStation BIOS directory set to $BIOS_DIR"
    echo "  ✓ DuckStation PS1 ROM directory set to $PS1_ROMS_DIR"
}

configure_duckstation_bios() {
    local bios_size

    echo 'Configuring DuckStation project paths...'
    ensure_duckstation_paths_configured
    mkdir -p "$BIOS_DIR"

    if [ ! -f "$BIOS_FILE" ]; then
        echo "  ! PS1 BIOS not found at $BIOS_FILE"
        echo "    Place your dumped BIOS there before launching PS1 games."
        return 0
    fi

    bios_size=$(stat -c%s "$BIOS_FILE" 2>/dev/null || stat -f%z "$BIOS_FILE" 2>/dev/null)
    if [ "$bios_size" -ne 524288 ]; then
        echo "  ! BIOS size is $bios_size bytes; expected 524288 bytes."
        echo '    PS1 games may fail until a valid BIOS is provided.'
        return 0
    fi

    rm -f "$DUCKSTATION_BIOS_DIR"/*.bin 2>/dev/null || true
    echo "  ✓ Valid PS1 BIOS found at $BIOS_FILE"
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

    for app_id in org.duckstation.DuckStation net.pcsx2.PCSX2 org.ppsspp.PPSSPP; do
        if flatpak info "$app_id" >/dev/null 2>&1; then
            echo "  ✓ $app_id installed"
        else
            echo "  ! $app_id not installed"
        fi
    done
}

show_usage() {
    cat <<EOF

Installation complete.

Next steps:
  1. Place DOS games in $PROJECT_DIR/Programs
  2. Place ROMs in $PROJECT_DIR/ROMs/{GB,GBA,PS1,PS2,PSP,N64}
  3. Run ./create_launchers.sh

PS1 note:
  Put your dumped BIOS at $BIOS_FILE before starting PS1 games.
EOF
}

main() {
    if ! command_exists apt; then
        echo 'This installer is intended for Debian/Ubuntu systems.' >&2
        echo 'Use install_emulators_fedora.sh on Fedora or install_emulators_macos.sh on macOS.' >&2
        exit 1
    fi

    echo '=== DOS_Launcher Debian/Ubuntu installer ==='
    echo "Project directory: $PROJECT_DIR"
    echo

    install_apt_packages
    echo
    setup_flatpak
    echo
    install_flatpak_apps
    echo
    apply_flatpak_overrides
    echo
    configure_duckstation_bios
    echo
    verify_installations
    show_usage
}

main "$@"