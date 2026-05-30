#!/usr/bin/env bash
# Launcher generator for DOS games and console ROMs on Linux and macOS.

set -euo pipefail
shopt -s nullglob nocaseglob

show_help() {
    cat <<'EOF'
Usage: ./create_launchers.sh [OPTIONS]

Generate launcher scripts for DOS games and console ROMs.

Options:
  -o, --output DIR    Output directory for launcher scripts (default: Launchers)
  -h, --help          Show this help message
EOF
}

relative_path() {
    local source target common_index source_count target_count index result

    source=$(cd "$1" && pwd)
    target=$(cd "$2" && pwd)

    local IFS='/'
    read -r -a source_parts <<< "${source#/}"
    read -r -a target_parts <<< "${target#/}"

    common_index=0
    source_count=${#source_parts[@]}
    target_count=${#target_parts[@]}

    while [ "$common_index" -lt "$source_count" ] \
        && [ "$common_index" -lt "$target_count" ] \
        && [ "${source_parts[$common_index]}" = "${target_parts[$common_index]}" ]; do
        common_index=$((common_index + 1))
    done

    result=""
    for ((index = common_index; index < source_count; index++)); do
        if [ -n "$result" ]; then
            result="$result/.."
        else
            result=".."
        fi
    done

    for ((index = common_index; index < target_count; index++)); do
        if [ -n "$result" ]; then
            result="$result/${target_parts[$index]}"
        else
            result="${target_parts[$index]}"
        fi
    done

    printf '%s\n' "${result:-.}"
}

shell_quote() {
    printf '%q' "$1"
}

file_size() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1"
}

find_largest_dos_executable() {
    local search_dir=$1
    local best_path=""
    local best_size=-1
    local candidate candidate_size

    for candidate in "$search_dir"/*; do
        [ -f "$candidate" ] || continue
        case "${candidate##*.}" in
            [eE][xX][eE]|[cC][oO][mM]|[bB][aA][tT])
                candidate_size=$(file_size "$candidate")
                if [ "$candidate_size" -gt "$best_size" ]; then
                    best_size=$candidate_size
                    best_path=$candidate
                fi
                ;;
        esac
    done

    printf '%s\n' "$best_path"
}

write_wrapper() {
    local launcher_path=$1
    local mode=$2
    local game_name=$3
    local target_dir=$4
    local target_file=$5
    local platform=${6:-}
    local game_name_q target_dir_q target_file_q platform_arg platform_q

    game_name_q=$(shell_quote "$game_name")
    target_dir_q=$(shell_quote "$target_dir")
    target_file_q=$(shell_quote "$target_file")
    platform_arg=""

    if [ -n "$platform" ]; then
        platform_q=$(shell_quote "$platform")
        platform_arg=" --platform $platform_q"
    fi

    cat > "$launcher_path" <<EOF
#!/usr/bin/env bash
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="\$(cd "\$SCRIPT_DIR/$REL_PATH" && pwd)"
exec "\$PROJECT_DIR/Configuration/launch_unix.sh" --project-dir "\$PROJECT_DIR" --mode $mode --game-name $game_name_q --target-dir $target_dir_q --file $target_file_q$platform_arg
EOF

    chmod +x "$launcher_path"
}

OUTPUT_DIR=""
while [ $# -gt 0 ]; do
    case "$1" in
        -o|--output)
            if [ $# -lt 2 ]; then
                echo "Error: missing value for $1" >&2
                exit 1
            fi
            OUTPUT_DIR=$2
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: unknown option '$1'" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROGRAMS_DIR="$BASE_DIR/Programs"
ROMS_DIR="$BASE_DIR/ROMs"
LOGS_DIR="$BASE_DIR/Logs"

if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$BASE_DIR/Launchers"
fi

mkdir -p "$OUTPUT_DIR" "$LOGS_DIR"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)
REL_PATH=$(relative_path "$OUTPUT_DIR" "$BASE_DIR")

echo "=== DOS_Launcher shell generator ==="
echo "Base directory: $BASE_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Project path from launchers: $REL_PATH"
echo

for program_dir in "$PROGRAMS_DIR"/*/; do
    [ -d "$program_dir" ] || continue

    program_name=$(basename "$program_dir")
    exe_path=$(find_largest_dos_executable "$program_dir")

    if [ -z "$exe_path" ]; then
        echo "Skipping $program_name: no DOS executable found"
        continue
    fi

    launcher_path="$OUTPUT_DIR/start_DOS_${program_name}.sh"
    write_wrapper "$launcher_path" dos "$program_name" "Programs/$program_name" "$(basename "$exe_path")"
    echo "Created $launcher_path"
done

for rom_dir in "$ROMS_DIR"/*/; do
    [ -d "$rom_dir" ] || continue

    platform=$(basename "$rom_dir")
    case "$platform" in
        GB)
            patterns=('*.gb' '*.gbc')
            ;;
        GBA)
            patterns=('*.gba')
            ;;
        PS1)
            patterns=('*.cue' '*.bin' '*.iso' '*.img')
            ;;
        PS2)
            patterns=('*.iso' '*.bin' '*.cue')
            ;;
        PSP)
            patterns=('*.iso' '*.cso')
            ;;
        N64)
            patterns=('*.n64' '*.z64' '*.v64')
            ;;
        *)
            echo "Skipping unsupported platform directory $platform"
            continue
            ;;
    esac

    for pattern in "${patterns[@]}"; do
        for rom_path in "$rom_dir"/$pattern; do
            [ -f "$rom_path" ] || continue
            rom_file=$(basename "$rom_path")
            rom_name=${rom_file%.*}

            if [ "$platform" = "PS1" ] && [[ "$rom_file" == *.bin ]]; then
                skip_bin=false
                for cue_file in "$rom_dir"/*.cue; do
                    [ -f "$cue_file" ] || continue
                    if grep -qF "$rom_file" "$cue_file" 2>/dev/null; then
                        skip_bin=true
                        break
                    fi
                done
                if [ "$skip_bin" = true ]; then
                    continue
                fi
            fi

            launcher_path="$OUTPUT_DIR/start_${platform}_${rom_name}.sh"
            write_wrapper "$launcher_path" rom "$rom_name" "ROMs/$platform" "$rom_file" "$platform"
            echo "Created $launcher_path"
        done
    done
done

echo
echo "Launcher generation complete."

