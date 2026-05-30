# Windows Setup

This guide covers the Windows layout for DOS_Launcher, where each emulator lives in its own folder under `Configuration/Emulators` and launchers are generated as `.bat` files.

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or newer
- A DOS_Launcher checkout on a local drive
- Your BIOS files in `BIOS/` when required

## Emulator Folder Layout

Extract each emulator into its own subfolder:

```text
Configuration\Emulators\
├── DOSBox\
├── DuckStation\
├── mGBA\
├── Mupen64Plus\
├── PCSX2\
└── PPSSPP\
```

The Windows runtime checks these folders first and then falls back to executables found in `PATH`.

## Recommended Folder Mapping

- `Configuration\Emulators\DOSBox` for DOSBox
- `Configuration\Emulators\mGBA` for mGBA
- `Configuration\Emulators\DuckStation` for DuckStation
- `Configuration\Emulators\PCSX2` for PCSX2
- `Configuration\Emulators\PPSSPP` for PPSSPP
- `Configuration\Emulators\Mupen64Plus` for Mupen64Plus

If the main `.exe` name differs from the usual one, keep it inside the correct folder. The launcher runtime will fall back to the first `.exe` it finds in that folder.

## BIOS Setup

Place BIOS files in `BIOS/`.

- PS1: put your dumped `scph1001.bin` in `BIOS/`
- PS2: PCSX2 may prompt for BIOS selection on first launch depending on the build you use

More details are in [BIOS/README.md](BIOS/README.md).

## Add Games

- DOS games go in `Programs/<GameName>/`
- Game Boy ROMs go in `ROMs/GB/`
- Game Boy Advance ROMs go in `ROMs/GBA/`
- PlayStation ROMs go in `ROMs/PS1/` and `ROMs/PS2/`
- PSP ROMs go in `ROMs/PSP/`
- N64 ROMs go in `ROMs/N64/`

## Generate Launchers

Open Command Prompt or PowerShell in the project root and run:

```bat
create_launchers.bat
```

Optional custom output directory:

```bat
create_launchers.bat -OutputDir C:\Games\Launchers
```

Launchers are created in `Launchers/` by default.

## Run Games

- Double-click any generated `start_*.bat` file
- DOS launchers start DOSBox in the game folder
- ROM launchers call the shared Windows runtime in `Configuration/launch_windows.ps1`
- Logs are written to `Logs/`

## First-Run Notes

- SmartScreen may warn the first time you open a launcher or emulator executable
- PCSX2 and DuckStation may ask for initial setup on first start
- If Defender blocks an extracted emulator, unblock the archive or extracted folder before running it

## Troubleshooting

- `DOSBox was not found.`
  Put `dosbox.exe` in `Configuration\Emulators\DOSBox`.

- `DuckStation was not found.` or similar
  Make sure the emulator was extracted into the matching folder under `Configuration\Emulators`.

- A launcher opens but the game does not start
  Check the matching log file in `Logs/` and confirm the ROM or DOS executable still exists.

- PS1 does not boot
  Verify that `BIOS\scph1001.bin` exists and is exactly `524288` bytes.