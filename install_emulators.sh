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
    echo "Setting up Flatpak..."

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

# Function to apply flatpak overrides for full access
apply_flatpak_overrides() {
    echo "Applying Flatpak overrides for full filesystem access..."
    
    FLATPAK_APPS=(
        "org.duckstation.DuckStation:DuckStation (PS1 emulator)"
        "org.ppsspp.PPSSPP:PPSSPP (PSP emulator)"
    )
    
    for app_info in "${FLATPAK_APPS[@]}"; do
        IFS=':' read -r app_id app_name <<< "$app_info"
        
        if flatpak list | grep -q "$app_id"; then
            echo "  Granting filesystem access to $app_name..."
            sudo flatpak override --filesystem=host "$app_id"
            echo "  ✓ Filesystem access granted for $app_name"
        fi
    done
}

# Function to setup DuckStation BIOS
setup_duckstation_bios() {
    echo "Setting up DuckStation BIOS..."
    
    BIOS_DIR="$PWD/BIOS"
    BIOS_FILE="$BIOS_DIR/scph1001.bin"
    
    # Configure DuckStation settings first (always set Paths)
    SETTINGS_FILE="$HOME/.var/app/org.duckstation.DuckStation/config/duckstation/settings.ini"
    BIOS_DIR_CONFIG="$PWD/BIOS"
    ROMS_DIR_CONFIG="$PWD/ROMs/PS1"
    
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo "  Creating default DuckStation configuration..."
        create_default_config
        echo "  ✓ Default configuration created"
    else
        echo "  ✓ DuckStation configuration already exists"
    fi
    
    # Always ensure BIOS and ROM Paths are set correctly
    ensure_duckstation_paths_configured
    
    # Check if BIOS directory exists
    mkdir -p "$BIOS_DIR"
    
    if [ ! -f "$BIOS_FILE" ]; then
        echo "PS1 BIOS file not found at $BIOS_FILE"
        echo "DuckStation requires an authentic PS1 BIOS file."
        echo "Download a PS1 BIOS file and place it as:"
        echo "     $BIOS_FILE"
        echo "For more information, see: $BIOS_DIR/README.md"
        echo "PS1 games will not work until a valid BIOS is provided."
        return 1
    else
        # Check if BIOS file size is correct (512KB)
        BIOS_SIZE=$(stat -c%s "$BIOS_FILE" 2>/dev/null || stat -f%z "$BIOS_FILE" 2>/dev/null)
        if [ "$BIOS_SIZE" -ne 524288 ]; then
            echo "BIOS file size is incorrect ($BIOS_SIZE bytes). PS1 BIOS should be exactly 524288 bytes (512KB)."
            echo "Please ensure you have a valid PS1 BIOS file."
            return 1
        fi
        
        echo "  ✓ Valid PS1 BIOS found at $BIOS_FILE"
        
        # Clean up any BIOS files in DuckStation's config directory to ensure it uses the project folder
        FLATPAK_BIOS_DIR="$HOME/.var/app/org.duckstation.DuckStation/config/duckstation/bios"
        if [ -d "$FLATPAK_BIOS_DIR" ]; then
            rm -f "$FLATPAK_BIOS_DIR"/*.bin 2>/dev/null || true
            echo "  ✓ Cleaned up BIOS files from DuckStation config directory"
        fi
        
        echo "  ✓ DuckStation will use BIOS from project folder: $BIOS_DIR"
    fi
}

create_default_config() {
    cat > "$SETTINGS_FILE" << 'EOF'
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
SearchDirectory = BIOS_DIR_CONFIG_PLACEHOLDER

[Graphics]
ResolutionScale = 2
TrueColor = true
TextureFilter = 1
PGXP = true
PGXPVertexCache = true

[Controller1]
Type = AnalogController
ButtonUp = Keyboard/W
ButtonDown = Keyboard/S
ButtonLeft = Keyboard/A
ButtonRight = Keyboard/D
ButtonSelect = Keyboard/Backspace
ButtonStart = Keyboard/Return
ButtonTriangle = Keyboard/I
ButtonCircle = Keyboard/L
ButtonCross = Keyboard/K
ButtonSquare = Keyboard/J
ButtonL1 = Keyboard/Q
ButtonR1 = Keyboard/E
ButtonL2 = Keyboard/1
ButtonR2 = Keyboard/3
AxisLeftX- = Keyboard/Left
AxisLeftX+ = Keyboard/Right
AxisLeftY- = Keyboard/Up
AxisLeftY+ = Keyboard/Down
AxisRightX- = Keyboard/Z
AxisRightX+ = Keyboard/X
AxisRightY- = Keyboard/C
AxisRightY+ = Keyboard/V

[MemoryCards]
Card1Type = PerGameTitle
Card2Type = PerGameTitle

[GameList]
RecursivePaths = ROMS_DIR_CONFIG_PLACEHOLDER
EOF
    # Replace the placeholder with actual path
    sed -i "s|BIOS_DIR_CONFIG_PLACEHOLDER|$BIOS_DIR_CONFIG|" "$SETTINGS_FILE"
    sed -i "s|ROMS_DIR_CONFIG_PLACEHOLDER|$ROMS_DIR_CONFIG|" "$SETTINGS_FILE"
}

# Function to ensure BIOS and ROM Paths are configured in DuckStation settings
ensure_duckstation_paths_configured() {
    SETTINGS_FILE="$HOME/.var/app/org.duckstation.DuckStation/config/duckstation/settings.ini"
    BIOS_DIR_CONFIG="$PWD/BIOS"
    ROMS_DIR_CONFIG="$PWD/ROMs/PS1"
    
    # Remove any existing Paths and SearchDirectory lines in BIOS section
    sed -i '/^\[BIOS\]/,/^\[/ { /^[[:space:]]*Paths[[:space:]]*=/d; /^[[:space:]]*SearchDirectory[[:space:]]*=/d; }' "$SETTINGS_FILE" 2>/dev/null || true
    
    # Add both SearchDirectory (which DuckStation checks first) and Paths
    sed -i "/^\[BIOS\]/a SearchDirectory = $BIOS_DIR_CONFIG" "$SETTINGS_FILE" 2>/dev/null || echo "  Warning: Could not update BIOS SearchDirectory"
    
    # Remove any existing RecursivePaths lines in GameList section
    sed -i '/^\[GameList\]/,/^\[/ { /^[[:space:]]*RecursivePaths[[:space:]]*=/d; }' "$SETTINGS_FILE" 2>/dev/null || true
    
    # Add the correct RecursivePaths setting after [GameList] section
    sed -i "/^\[GameList\]/a RecursivePaths = $ROMS_DIR_CONFIG" "$SETTINGS_FILE" 2>/dev/null || echo "  Warning: Could not update ROMs path"
    
    echo "  ✓ DuckStation BIOS SearchDirectory configured to: $BIOS_DIR_CONFIG"
    echo "  ✓ DuckStation ROMs Paths configured to use project folder: $ROMS_DIR_CONFIG"
}

# Function to verify installations
verify_installations() {
    echo "Verifying installations..."

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

    apply_flatpak_overrides
    echo

    setup_duckstation_bios
    echo

    verify_installations
    echo

    show_usage
}

# Run main function
main "$@"