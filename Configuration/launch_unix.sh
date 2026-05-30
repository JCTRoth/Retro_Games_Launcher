#!/usr/bin/env bash
# Shared launcher runtime for Linux and macOS launchers.

set -uo pipefail

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

resolve_command() {
    local candidate
    for candidate in "$@"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done
    return 1
}

flatpak_installed() {
    command -v flatpak >/dev/null 2>&1 && flatpak info "$1" >/dev/null 2>&1
}

find_app_executable() {
    local app_name bundle executable
    for app_name in "$@"; do
        for bundle in "/Applications/$app_name.app" "$HOME/Applications/$app_name.app"; do
            if [ -d "$bundle/Contents/MacOS" ]; then
                for executable in "$bundle/Contents/MacOS"/*; do
                    [ -f "$executable" ] || continue
                    [ -x "$executable" ] || continue
                    printf '%s\n' "$executable"
                    return 0
                done
            fi
        done
    done
    return 1
}

write_log_header() {
    {
        echo "==========================================="
        echo "$1"
        echo "==========================================="
        echo "Game: $GAME_NAME"
        if [ -n "$PLATFORM" ]; then
            echo "Platform: $PLATFORM"
        fi
        echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Project Directory: $PROJECT_DIR"
        echo "Working Directory: $TARGET_DIR"
        echo "Target File: $TARGET_FILE"
        echo "Emulator: $EMULATOR_LABEL"
        echo "Config: $CONFIG_LABEL"
        echo "Logfile: $LOGFILE"
        echo "System: $(uname -s) $(uname -r)"
        echo "==========================================="
        echo
    } > "$LOGFILE"
}

write_log_footer() {
    {
        echo
        echo "==========================================="
        echo "Ended: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Exit Code: $1"
        echo "==========================================="
    } >> "$LOGFILE"
}

run_with_log() {
    "$@" 2>&1 | tee -a "$LOGFILE"
    return ${PIPESTATUS[0]}
}

MODE=""
PLATFORM=""
GAME_NAME=""
TARGET_DIR_REL=""
TARGET_FILE=""
PROJECT_DIR=""

while [ $# -gt 0 ]; do
    case "$1" in
        --mode)
            [ $# -ge 2 ] || die "Missing value for --mode"
            MODE=$2
            shift 2
            ;;
        --platform)
            [ $# -ge 2 ] || die "Missing value for --platform"
            PLATFORM=$2
            shift 2
            ;;
        --game-name)
            [ $# -ge 2 ] || die "Missing value for --game-name"
            GAME_NAME=$2
            shift 2
            ;;
        --target-dir)
            [ $# -ge 2 ] || die "Missing value for --target-dir"
            TARGET_DIR_REL=$2
            shift 2
            ;;
        --file)
            [ $# -ge 2 ] || die "Missing value for --file"
            TARGET_FILE=$2
            shift 2
            ;;
        --project-dir)
            [ $# -ge 2 ] || die "Missing value for --project-dir"
            PROJECT_DIR=$2
            shift 2
            ;;
        *)
            die "Unknown option '$1'"
            ;;
    esac
done

[ -n "$MODE" ] || die "--mode is required"
[ -n "$GAME_NAME" ] || die "--game-name is required"
[ -n "$TARGET_DIR_REL" ] || die "--target-dir is required"
[ -n "$TARGET_FILE" ] || die "--file is required"

if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
else
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)
fi

TARGET_DIR="$PROJECT_DIR/$TARGET_DIR_REL"
TARGET_PATH="$TARGET_DIR/$TARGET_FILE"
mkdir -p "$PROJECT_DIR/Logs"

[ -d "$TARGET_DIR" ] || die "Target directory does not exist: $TARGET_DIR"
[ -f "$TARGET_PATH" ] || die "Target file does not exist: $TARGET_PATH"

LOG_BASENAME=$GAME_NAME
if [ "$MODE" = "rom" ]; then
    [ -n "$PLATFORM" ] || die "--platform is required for ROM launchers"
    LOG_BASENAME="${PLATFORM}_${GAME_NAME}"
fi
LOGFILE="$PROJECT_DIR/Logs/$LOG_BASENAME.log"

EMULATOR_LABEL=""
CONFIG_LABEL="default"
RUN_FROM_DIR="$TARGET_DIR"
COMMAND=()

case "$MODE" in
    dos)
        CONFIG_PATH="$PROJECT_DIR/Configuration/dosbox.conf"
        if [ -f "$TARGET_DIR/dosbox.conf" ]; then
            CONFIG_PATH="$TARGET_DIR/dosbox.conf"
        fi
        CONFIG_LABEL=$CONFIG_PATH

        if emulator_path=$(resolve_command dosbox dosbox-x dosbox-staging); then
            COMMAND=("$emulator_path" "$TARGET_FILE" -conf "$CONFIG_PATH" -fullscreen -exit)
            EMULATOR_LABEL=$emulator_path
        elif [ "$(uname -s)" = "Darwin" ] && emulator_path=$(find_app_executable DOSBox-X DOSBox 'DOSBox Staging'); then
            COMMAND=("$emulator_path" "$TARGET_FILE" -conf "$CONFIG_PATH" -fullscreen -exit)
            EMULATOR_LABEL=$emulator_path
        else
            die "No supported DOSBox binary found. Install DOSBox or DOSBox-X first."
        fi
        ;;
    rom)
        ROM_PATH=$TARGET_PATH
        case "$PLATFORM" in
            GB|GBA)
                if emulator_path=$(resolve_command mgba-qt mgba mGBA); then
                    COMMAND=("$emulator_path" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                elif [ "$(uname -s)" = "Darwin" ] && emulator_path=$(find_app_executable mGBA); then
                    COMMAND=("$emulator_path" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                else
                    die "mGBA was not found. Install it with the platform installer first."
                fi
                ;;
            PS1)
                if emulator_path=$(resolve_command duckstation-qt duckstation); then
                    COMMAND=("$emulator_path" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                elif flatpak_installed org.duckstation.DuckStation; then
                    COMMAND=(flatpak run "--filesystem=$PROJECT_DIR" org.duckstation.DuckStation "$ROM_PATH")
                    EMULATOR_LABEL='flatpak run org.duckstation.DuckStation'
                elif [ "$(uname -s)" = "Darwin" ] && emulator_path=$(find_app_executable DuckStation); then
                    COMMAND=("$emulator_path" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                else
                    die "DuckStation was not found. Install it with the platform installer first."
                fi
                ;;
            PS2)
                if emulator_path=$(resolve_command pcsx2-qt pcsx2); then
                    COMMAND=("$emulator_path" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                elif flatpak_installed net.pcsx2.PCSX2; then
                    COMMAND=(flatpak run "--filesystem=$PROJECT_DIR" net.pcsx2.PCSX2 "$ROM_PATH")
                    EMULATOR_LABEL='flatpak run net.pcsx2.PCSX2'
                elif [ "$(uname -s)" = "Darwin" ] && emulator_path=$(find_app_executable PCSX2); then
                    COMMAND=("$emulator_path" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                else
                    die "PCSX2 was not found. Install it with the platform installer first."
                fi
                ;;
            PSP)
                if emulator_path=$(resolve_command PPSSPPQt PPSSPPQt64 PPSSPP ppsspp); then
                    COMMAND=("$emulator_path" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                elif flatpak_installed org.ppsspp.PPSSPP; then
                    COMMAND=(flatpak run "--filesystem=$PROJECT_DIR" org.ppsspp.PPSSPP "$ROM_PATH")
                    EMULATOR_LABEL='flatpak run org.ppsspp.PPSSPP'
                elif [ "$(uname -s)" = "Darwin" ] && emulator_path=$(find_app_executable PPSSPP); then
                    COMMAND=("$emulator_path" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                else
                    die "PPSSPP was not found. Install it with the platform installer first."
                fi
                ;;
            N64)
                CONFIG_LABEL="$PROJECT_DIR/Configuration/mupen64plus.cfg"
                if emulator_path=$(resolve_command mupen64plus); then
                    COMMAND=("$emulator_path" --fullscreen --configdir "$PROJECT_DIR/Configuration" "$ROM_PATH")
                    EMULATOR_LABEL=$emulator_path
                else
                    die "Mupen64Plus was not found. Install it with the platform installer first."
                fi
                ;;
            *)
                die "Unsupported ROM platform '$PLATFORM'"
                ;;
        esac
        ;;
    *)
        die "Unsupported mode '$MODE'"
        ;;
esac

write_log_header "${MODE^^} LAUNCHER LOG"

cd "$RUN_FROM_DIR" || die "Failed to enter $RUN_FROM_DIR"
run_with_log "${COMMAND[@]}"
exit_code=$?
write_log_footer "$exit_code"
exit "$exit_code"