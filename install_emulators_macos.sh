#!/usr/bin/env bash
# macOS/Homebrew emulator installation script for DOS_Launcher.

set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIOS_FILE="$PROJECT_DIR/BIOS/scph1001.bin"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

brew_formula_exists() {
    brew info --formula "$1" >/dev/null 2>&1
}

brew_cask_exists() {
    brew info --cask "$1" >/dev/null 2>&1
}

ensure_formula_installed() {
    local formula_name=$1
    if brew list --formula "$formula_name" >/dev/null 2>&1; then
        echo "  ✓ $formula_name already installed"
    else
        brew install "$formula_name"
        echo "  ✓ $formula_name installed"
    fi
}

ensure_cask_installed() {
    local cask_name=$1
    if brew list --cask "$cask_name" >/dev/null 2>&1; then
        echo "  ✓ $cask_name already installed"
    else
        brew install --cask "$cask_name"
        echo "  ✓ $cask_name installed"
    fi
}

select_formula() {
    local candidate
    for candidate in "$@"; do
        if brew_formula_exists "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

main() {
    local dosbox_formula

    if [ "$(uname -s)" != 'Darwin' ]; then
        echo 'This installer is intended for macOS.' >&2
        exit 1
    fi

    if ! command_exists brew; then
        echo 'Homebrew is required. Install it first from https://brew.sh/' >&2
        exit 1
    fi

    echo '=== DOS_Launcher macOS installer ==='
    echo "Project directory: $PROJECT_DIR"
    echo

    brew update

    dosbox_formula=$(select_formula dosbox dosbox-x dosbox-staging || true)
    if [ -z "$dosbox_formula" ]; then
        echo 'No supported DOSBox Homebrew formula was found.' >&2
        exit 1
    fi

    echo 'Installing Homebrew formulae...'
    ensure_formula_installed "$dosbox_formula"
    ensure_formula_installed mgba
    ensure_formula_installed mupen64plus
    echo

    echo 'Installing Homebrew casks...'
    for cask_name in duckstation pcsx2 ppsspp; do
        if brew_cask_exists "$cask_name"; then
            ensure_cask_installed "$cask_name"
        else
            echo "  ! Skipping unavailable cask: $cask_name"
        fi
    done
    echo

    echo 'Verification:'
    for check in dosbox dosbox-x mgba mupen64plus; do
        if command_exists "$check"; then
            echo "  ✓ $check -> $(command -v "$check")"
        fi
    done

    echo
    echo 'Next steps:'
    echo "  1. Put your PS1 BIOS at $BIOS_FILE"
    echo '  2. Place games in Programs/ and ROMs/'
    echo '  3. Run ./create_launchers.sh'
    echo '  4. On first launch, allow macOS to open the installed emulator apps if prompted.'
}

main "$@"