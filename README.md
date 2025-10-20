# DOSBox & ROM Launcher

This program creates launcher scripts that allow you to run DOS games and console ROMs with a single double-click.
It uses a default `dosbox.conf` located in the `/Configuration` folder for DOS games.
If a `dosbox.conf` is present in a program's folder, the launcher will use that configuration instead of the global one.

## Features

- **DOS Games**: Automatic launcher generation for DOSBox programs
- **Console ROMs**: Support for Game Boy, PS1, PSP, and N64 ROMs
- **Logging**: All sessions are logged with timestamps
- **Cross-platform**: Works on Linux/macOS (.sh) and Windows (.bat)

## Usage

1. **Install Emulators** (Linux only)
   ```bash
   ./install_emulators.sh
   ```
   This script installs all required emulators:
   - DOSBox (DOS games)
   - mGBA (Game Boy)
   - DuckStation (PS1)
   - PPSSPP (PSP)
   - Mupen64Plus (N64)

2. **Add Games/ROMs**
   - DOS games go in `Programs/` folder
   - ROMs go in `ROMs/{GB,PS1,PSP,N64}/` folders

3. **Generate Launchers**
   - **Linux/macOS:** Run `./create_launchers.sh`
   - **Windows:** Run the corresponding `.bat` file
   - **Custom output directory:** Use `./create_launchers.sh -o /path/to/output`
   - Launchers appear as `start_*Name*.sh` files

4. **Run Games**
   - Double-click any `start_*Name*.sh` launcher
   - Logs are saved in `logs/` folder

## Folder Structure

```
DOS_Launcher/                  # Main Folder
├── Configuration/             # DOSBox configuration
│   ├── DosBox/                # Optional: Local DOSBox installation
│   └── dosbox.conf            # Global DOSBox configuration
├── Programs/                  # DOS program folders
│   └── Blood/                 # Example DOS game
├── ROMs/                      # Console ROM folders
│   ├── GB/                    # Game Boy ROMs (.gb, .gbc)
│   ├── PS1/                   # PlayStation 1 ROMs (.bin, .cue, .iso, .img)
│   ├── PSP/                   # PSP ROMs (.iso, .cso)
│   └── N64/                   # Nintendo 64 ROMs (.n64, .z64, .v64)
├── logs/                      # Session logs
├── create_launchers.sh        # Script to generate launchers
├── start_Blood.sh             # Example DOS launcher
└── start_GB_SuperMario.sh     # Example ROM launcher
```

## Supported Platforms

| Platform | Emulator | File Extensions | Installation |
|----------|----------|-----------------|--------------|
| DOS | DOSBox | .exe | Auto (Linux) / Manual (Win/Mac) |
| Game Boy | mGBA | .gb, .gbc | Auto |
| PS1 | DuckStation | .bin, .cue, .iso, .img | Auto |
| PSP | PPSSPP | .iso, .cso | Auto |
| N64 | Mupen64Plus | .n64, .z64, .v64 | Auto |

## Installation Script

The `install_emulators.sh` script automatically installs all required emulators on Ubuntu/Debian systems:

- **APT packages**: dosbox, mgba-qt, mupen64plus-qt
- **Flatpak apps**: DuckStation (PS1), PPSSPP (PSP)
- **Dependencies**: Sets up Flatpak and Flathub repository if needed

Run it once after cloning the repository:
```bash
./install_emulators.sh
```

The script checks what's already installed and only installs missing components.

## Controls

- **DOSBox**: ALT-ENTER (fullscreen), CTRL-F9 (quit), CTRL-F10 (release mouse)
- **Emulators**: Use emulator-specific controls (usually shown in menus)

## Notes/Tips

- Each DOS program folder can include its own `dosbox.conf` to override the global configuration
- ROM launchers automatically detect and use the correct emulator
- All gaming sessions are logged with timestamps in the `logs/` folder
- For more DOSBox key combinations, see: https://www.dosbox.com/wiki/Special_Keys
- TODO: Test on Windows

## Command Line Options

The `create_launchers.sh` script supports the following options:

```bash
./create_launchers.sh [OPTIONS]

Options:
  -o, --output DIR    Specify output directory for launcher scripts
                      (default: current directory)
  -h, --help          Show help message and usage examples

Examples:
  ./create_launchers.sh                          # Default: launchers in current dir
  ./create_launchers.sh -o ~/Desktop/Games       # Launchers on Desktop
  ./create_launchers.sh --output ./launchers     # Launchers in subdirectory
```

When using a custom output directory, launcher scripts will use relative paths to access the Programs/, ROMs/, and logs/ directories from the main project folder.
