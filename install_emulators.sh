#!/bin/bash
# Ubuntu Emulator Installation Script
# Installs all required emulators for DOS_Launcher system
# Supports: DOSBox, Game Boy (mGBA), PS1 (DuckStation), PSP (PPSSPP), N64 (Mupen64Plus)

set -e  # Exit on any error

echo "=== DOS_Launcher Emulator Installation Script ==="
echo "This script will install all required emulators for gaming"
echo

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install apt packages
install_apt_packages() {
    echo "Installing APT packages..."
    sudo apt update

    # List of packages to install
    PACKAGES=(
        dosbox          # DOS games
        mgba-qt         # Game Boy
        mupen64plus-qt  # N64
    )

    # Check which packages are already installed
    TO_INSTALL=()
    for pkg in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            TO_INSTALL+=("$pkg")
        else
            echo "  ✓ $pkg already installed"
        fi
    done

    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        echo "  Installing: ${TO_INSTALL[*]}"
        sudo apt install -y "${TO_INSTALL[@]}"
        echo "  ✓ APT packages installed successfully"
    else
        echo "  ✓ All APT packages already installed"
    fi
}

# Function to setup flatpak
setup_flatpak() {
    echo "📦 Setting up Flatpak..."

    if ! command_exists flatpak; then
        echo "  Installing Flatpak..."
        sudo apt install -y flatpak
    else
        echo "  ✓ Flatpak already installed"
    fi

    # Add Flathub repository if not already added
    if ! flatpak remotes | grep -q flathub; then
        echo "  Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    else
        echo "  ✓ Flathub repository already added"
    fi
}

# Function to install flatpak applications
install_flatpak_apps() {
    echo " Installing Flatpak applications..."

    FLATPAK_APPS=(
        "org.duckstation.DuckStation:DuckStation (PS1 emulator)"
        "org.ppsspp.PPSSPP:PPSSPP (PSP emulator)"
    )

    for app_info in "${FLATPAK_APPS[@]}"; do
        IFS=':' read -r app_id app_name <<< "$app_info"

        if ! flatpak list | grep -q "$app_id"; then
            echo "  Installing $app_name..."
            flatpak install -y flathub "$app_id"
            echo "  ✓ $app_name installed"
        else
            echo "  ✓ $app_name already installed"
        fi
    done
}

# Function to verify installations
verify_installations() {
    echo "🔍 Verifying installations..."

    # Check APT packages
    APT_CHECKS=(
        "dosbox:DOSBox"
        "mgba-qt:mGBA (Game Boy)"
        "mupen64plus-qt:Mupen64Plus (N64)"
    )

    for check_info in "${APT_CHECKS[@]}"; do
        IFS=':' read -r cmd name <<< "$check_info"
        if command_exists "$cmd"; then
            echo "  ✓ $name: $(which $cmd)"
        else
            echo "  ✗ $name: NOT FOUND"
        fi
    done

    # Check Flatpak applications
    FLATPAK_CHECKS=(
        "org.duckstation.DuckStation:DuckStation (PS1)"
        "org.ppsspp.PPSSPP:PPSSPP (PSP)"
    )

    for check_info in "${FLATPAK_CHECKS[@]}"; do
        IFS=':' read -r app_id name <<< "$check_info"
        if flatpak list | grep -q "$app_id"; then
            echo "  ✓ $name: Installed via Flatpak"
        else
            echo "  ✗ $name: NOT FOUND"
        fi
    done
}

# Function to show usage information
show_usage() {
    echo
    echo "Emulator Installation Complete!"
    echo
    echo "Supported platforms:"
    echo "  • DOSBox: DOS games (.exe files)"
    echo "  • mGBA: Game Boy (.gb, .gbc files)"
    echo "  • DuckStation: PlayStation 1 (.bin, .cue, .iso, .img files)"
    echo "  • PPSSPP: PSP (.iso, .cso files)"
    echo "  • Mupen64Plus: Nintendo 64 (.n64, .z64, .v64 files)"
    echo
    echo "To generate launchers for your games:"
    echo "  1. Place DOS games in Programs/ folder"
    echo "  2. Place ROMs in ROMs/{GB,PS1,PSP,N64}/ folders"
    echo "  3. Run: ./create_launchers.sh"
    echo "Done"
}

# Main installation process
main() {
    echo "Starting emulator installation..."
    echo

    install_apt_packages
    echo

    setup_flatpak
    echo

    install_flatpak_apps
    echo

    verify_installations
    echo

    show_usage
}

# Run main function
main "$@"