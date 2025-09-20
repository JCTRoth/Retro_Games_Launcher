#!/bin/bash
# Launcher generator for DOSBox programs with relative config paths
# Supports Linux/macOS (.sh) and Windows (.bat)

BASE_DIR="$(pwd)"
PROGRAMS_DIR="$BASE_DIR/Programs"
GLOBAL_CONFIG="../Configuration/dosbox.conf"
LOCAL_DOSBOX="$BASE_DIR/Configuration/DosBox/dosbox.exe"

echo "=== DOSBox Launcher Generator ==="
echo "Base directory: $BASE_DIR"
echo "Programs directory: $PROGRAMS_DIR"
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
    SCRIPT="$BASE_DIR/start_${PROG}.sh"
    cat > "$SCRIPT" <<EOF
#!/bin/bash
cd "\$(dirname "\$0")/Programs/$PROG" || exit
"$DOSBOX_CMD" "$(basename "$EXE")" -conf "$CONFIG" -fullscreen -exit
EOF
    chmod +x "$SCRIPT"
    echo "  Created launcher: $SCRIPT"
    echo
done

echo "=== Launcher generation complete ==="

