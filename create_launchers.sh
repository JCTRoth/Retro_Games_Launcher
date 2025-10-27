#!/bin/bash
# Launcher generator for DOSBox programs and console ROMs
# Supports DOSBox (.sh) and console emulators (GB, GBA, PS1, PS2, PSP, N64)
# Supports Linux/macOS (.sh) and Windows (.bat)

# Parse command line arguments
OUTPUT_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Generate launcher scripts for DOS games and console ROMs"
            echo ""
            echo "Options:"
            echo "  -o, --output DIR    Output directory for launcher scripts (default: current directory)"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Generate launchers in current directory"
            echo "  $0 -o ~/Desktop/Launchers   # Generate launchers in ~/Desktop/Launchers"
            echo "  $0 --output ./launchers     # Generate launchers in ./launchers subdirectory"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Set default output directory if not specified
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$(pwd)/Launchers"
else
    # Convert relative path to absolute
    OUTPUT_DIR="$(cd "$OUTPUT_DIR" 2>/dev/null && pwd)"
    if [ $? -ne 0 ]; then
        echo "Error: Output directory '$OUTPUT_DIR' does not exist or is not accessible"
        exit 1
    fi
fi

BASE_DIR="$(pwd)"
PROGRAMS_DIR="$BASE_DIR/Programs"
ROMS_DIR="$BASE_DIR/ROMs"
GLOBAL_CONFIG="$BASE_DIR/Configuration/dosbox.conf"
LOCAL_DOSBOX="$BASE_DIR/Configuration/DosBox/dosbox.exe"
LOGS_DIR="$BASE_DIR/Logs"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "=== DOSBox & ROM Launcher Generator ==="
echo "Base directory: $BASE_DIR"
echo "Programs directory: $PROGRAMS_DIR"
echo "Output directory: $OUTPUT_DIR"
echo

# Calculate relative path from output directory to base directory
if [ "$OUTPUT_DIR" = "$BASE_DIR" ]; then
    REL_PATH=""
else
    # Calculate relative path from output dir to base dir
    REL_PATH=$(python3 -c "
import os.path
print(os.path.relpath('$BASE_DIR', '$OUTPUT_DIR'))
" 2>/dev/null || echo "..")
fi

echo "Relative path: '$REL_PATH'"
echo

# Determine DOSBox command
if command -v dosbox &> /dev/null; then
    DOSBOX_CMD="dosbox"
    echo "DOSBox found in PATH: $DOSBOX_CMD"
else
    if [ -f "$LOCAL_DOSBOX" ]; then
        DOSBOX_CMD="$LOCAL_DOSBOX"
        echo "DOSBox not found in PATH. Using local DOSBox: $DOSBOX_CMD"
    else
        # Attempt install on Linux
        if [[ "$(uname -s)" != "Darwin" ]]; then
            echo "DOSBox not found. Installing via apt..."
            sudo apt update && sudo apt install -y dosbox
            DOSBOX_CMD="dosbox"
        else
            echo "DOSBox not found and no local copy available. Please install DOSBox manually."
            exit 1
        fi
    fi
fi
echo

# Iterate program folders
for dir in "$PROGRAMS_DIR"/*/; do
    [ -d "$dir" ] || continue
    PROG=$(basename "$dir")
    echo "Processing program folder: $PROG"

    # Find main EXE (largest if multiple)
    EXE=$(find "$dir" -maxdepth 1 -type f -iname "*.exe" -exec ls -s {} + 2>/dev/null | sort -nr | head -n 1 | awk '{print $2}')
    if [ -z "$EXE" ]; then
        echo "  No .EXE found in $PROG, skipping."
        echo
        continue
    fi
    echo "  Detected main EXE: $EXE"

    # Use local config if exists
    if [ -f "$dir/dosbox.conf" ]; then
        CONFIG="dosbox.conf"
        echo "  Using local config: $CONFIG"
    else
        CONFIG="$GLOBAL_CONFIG"
        echo "  Using global config: $CONFIG"
    fi

    # Create OS-specific launcher
    SCRIPT="$OUTPUT_DIR/start_DOS_${PROG}.sh"
    if [ -z "$REL_PATH" ]; then
        REL_PREFIX="/"
    else
        REL_PREFIX="/$REL_PATH/"
    fi
    cat > "$SCRIPT" <<EOF
#!/bin/bash
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
LOGFILE="\$SCRIPT_DIR${REL_PREFIX}Logs/${PROG}.log"
cd "\$(dirname "\$0")${REL_PREFIX}Programs/$PROG" || exit
echo "===========================================" > "\$LOGFILE"
echo "DOS GAME LAUNCHER LOG" >> "\$LOGFILE"
echo "===========================================" >> "\$LOGFILE"
echo "Game: $PROG" >> "\$LOGFILE"
echo "Started: \$(date '+%Y-%m-%d %H:%M:%S')" >> "\$LOGFILE"
echo "Working Directory: \$(pwd)" >> "\$LOGFILE"
echo "Executable: $(basename "$EXE")" >> "\$LOGFILE"
echo "DOSBox Command: $DOSBOX_CMD" >> "\$LOGFILE"
echo "Config File: ${REL_PREFIX}Configuration/dosbox.conf" >> "\$LOGFILE"
echo "Logfile: \$LOGFILE" >> "\$LOGFILE"
echo "System: \$(uname -s) \$(uname -r)" >> "\$LOGFILE"
echo "===========================================" >> "\$LOGFILE"
echo "" >> "\$LOGFILE"
"$DOSBOX_CMD" "$(basename "$EXE")" -conf "${REL_PREFIX}Configuration/dosbox.conf" -fullscreen -exit 2>&1 | tee -a "\$LOGFILE"
EXIT_CODE=\${PIPESTATUS[0]}
echo "" >> "\$LOGFILE"
echo "===========================================" >> "\$LOGFILE"
echo "Ended: \$(date '+%Y-%m-%d %H:%M:%S')" >> "\$LOGFILE"
echo "Exit Code: \$EXIT_CODE" >> "\$LOGFILE"
echo "===========================================" >> "\$LOGFILE"
EOF
    chmod +x "$SCRIPT"
    echo "  Created launcher: $SCRIPT"
    echo
done

echo "=== ROM Launcher Generator ==="
echo "ROMs directory: $ROMS_DIR"
echo

# Process ROM folders
for rom_dir in "$ROMS_DIR"/*/; do
    [ -d "$rom_dir" ] || continue
    PLATFORM=$(basename "$rom_dir")
    echo "Processing ROM platform: $PLATFORM"

    # Determine emulator based on platform
    CONFIG_CMD=""
    case "$PLATFORM" in
        "GB")
            EMULATOR_CMD="mgba-qt"
            CONFIG_CMD="-4 -C ports.qt.scaleMultiplier=4 -C gba.video.shader=/usr/share/mgba/shaders/xbr-lv3.shader"
            EXTENSIONS=("*.gb" "*.gbc")
            ;;
        "GBA")
            EMULATOR_CMD="mgba-qt"
            CONFIG_CMD="-4 -C ports.qt.scaleMultiplier=4 -C gba.video.shader=/usr/share/mgba/shaders/gba-color.shader"
            EXTENSIONS=("*.gba")
            ;;
        "PS1")
            EMULATOR_CMD="flatpak run --filesystem=\$PROJECT_DIR org.duckstation.DuckStation"
            EXTENSIONS=("*.cue" "*.bin" "*.iso" "*.img")
            ;;
        "PS2")
            EMULATOR_CMD="flatpak run --filesystem=\$PROJECT_DIR net.pcsx2.PCSX2"
            EXTENSIONS=("*.iso" "*.bin" "*.cue")
            ;;
        "PSP")
            EMULATOR_CMD="flatpak run org.ppsspp.PPSSPP"
            EXTENSIONS=("*.iso" "*.cso")
            ;;
        "N64")
            EMULATOR_CMD="mupen64plus"
            CONFIG_CMD="--fullscreen --configdir \"\$SCRIPT_DIR${REL_PREFIX}Configuration\""
            EXTENSIONS=("*.n64" "*.z64" "*.v64")
            ;;
        *)
            echo "  Unknown platform $PLATFORM, skipping."
            echo
            continue
            ;;
    esac

    # Find ROM files
    ROM_COUNT=0
    for ext in "${EXTENSIONS[@]}"; do
        while IFS= read -r -d '' rom_file; do
            ROM=$(basename "$rom_file")
            ROM_NAME="${ROM%.*}"  # Remove extension
            
            # For PS1, skip .bin files if any .cue exists in the directory
            if [[ "$PLATFORM" == "PS1" && "$ROM" == *.bin ]]; then
                # Check if this .bin file is referenced by any .cue file
                SKIP_BIN=false
                for cue_file in "$rom_dir"/*.cue; do
                    if [ -f "$cue_file" ]; then
                        # Check if this .bin file is mentioned in any .cue file
                        if grep -qF "$ROM" "$cue_file" 2>/dev/null; then
                            echo "  Skipping $ROM (referenced in $(basename "$cue_file"))"
                            SKIP_BIN=true
                            break
                        fi
                    fi
                done
                [ "$SKIP_BIN" = true ] && continue
            fi
            
            echo "  Processing ROM: $ROM"

            # Create launcher for this ROM
            SCRIPT="$OUTPUT_DIR/start_${PLATFORM}_${ROM_NAME}.sh"
            if [ -z "$REL_PATH" ]; then
                REL_PREFIX="/"
            else
                REL_PREFIX="/$REL_PATH/"
            fi
            
            # Special handling for PS1 to use full path due to Flatpak sandboxing
            ROM_ARG="\"$ROM\""
            if [[ "$PLATFORM" == "PS1" ]]; then
                ROM_ARG="\"\$(pwd)/$ROM\""
            fi
            
            cat > "$SCRIPT" <<EOF
#!/bin/bash
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
PROJECT_DIR="\$(dirname "\$SCRIPT_DIR")"
LOGFILE="\$PROJECT_DIR/Logs/${PLATFORM}_${ROM_NAME}.log"
cd "\$(dirname "\$0")${REL_PREFIX}ROMs/$PLATFORM" || exit
echo "===========================================" > "\$LOGFILE"
echo "$PLATFORM EMULATOR LAUNCHER LOG" >> "\$LOGFILE"
echo "===========================================" >> "\$LOGFILE"
echo "Game: $ROM_NAME" >> "\$LOGFILE"
echo "Platform: $PLATFORM" >> "\$LOGFILE"
echo "Started: \$(date '+%Y-%m-%d %H:%M:%S')" >> "\$LOGFILE"
echo "ROM File: $ROM" >> "\$LOGFILE"
echo "ROM Path: \$(pwd)/$ROM" >> "\$LOGFILE"
echo "Emulator: $EMULATOR_CMD" >> "\$LOGFILE"
echo "Config: $CONFIG_CMD" >> "\$LOGFILE"
echo "Working Directory: \$(pwd)" >> "\$LOGFILE"
echo "Logfile: \$LOGFILE" >> "\$LOGFILE"
echo "System: \$(uname -s) \$(uname -r)" >> "\$LOGFILE"
echo "===========================================" >> "\$LOGFILE"
echo "" >> "\$LOGFILE"
$EMULATOR_CMD $CONFIG_CMD $ROM_ARG 2>&1 | tee -a "\$LOGFILE"
EXIT_CODE=\${PIPESTATUS[0]}
echo "" >> "\$LOGFILE"
echo "===========================================" >> "\$LOGFILE"
echo "Ended: \$(date '+%Y-%m-%d %H:%M:%S')" >> "\$LOGFILE"
echo "Exit Code: \$EXIT_CODE" >> "\$LOGFILE"
echo "===========================================" >> "\$LOGFILE"
EOF
            chmod +x "$SCRIPT"
            echo "  Created launcher: $SCRIPT"
            ((ROM_COUNT++))
        done < <(find "$rom_dir" -maxdepth 1 -type f \( -iname "${ext}" \) -print0 2>/dev/null)
    done

    if [ $ROM_COUNT -eq 0 ]; then
        echo "  No ROM files found in $PLATFORM"
    fi
    echo
done

echo "=== Launcher generation complete ==="

