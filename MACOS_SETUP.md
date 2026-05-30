# macOS Setup

This guide covers the Homebrew-based macOS setup for DOS_Launcher.

## Requirements

- macOS with Homebrew installed
- Terminal access
- A DOS_Launcher checkout on a local disk
- BIOS files in `BIOS/` when required

If Homebrew is not installed yet, install it first from https://brew.sh/.

## Install Emulators

From the project root, run:

```bash
./install_emulators_macos.sh
```

The installer:

- updates Homebrew
- installs a supported DOSBox formula
- installs `mgba`
- installs `mupen64plus`
- installs the `duckstation`, `pcsx2`, and `ppsspp` casks when available

## BIOS Setup

Put your dumped BIOS files in `BIOS/`.

- PS1: `BIOS/scph1001.bin`
- PS2: configure in PCSX2 if your build requires it

See [BIOS/README.md](BIOS/README.md) for filename and size notes.

## Add Games

- DOS games go in `Programs/<GameName>/`
- ROMs go in `ROMs/GB`, `ROMs/GBA`, `ROMs/PS1`, `ROMs/PS2`, `ROMs/PSP`, and `ROMs/N64`

## Generate Launchers

Run:

```bash
./create_launchers.sh
```

Optional custom output directory:

```bash
./create_launchers.sh -o ~/Desktop/Launchers
```

Generated launchers are `.sh` files.

## First Launch on macOS

macOS may block newly installed emulator apps on first start.

If that happens:

1. Right-click the app or launcher and choose `Open`
2. Confirm the security prompt
3. Retry the launcher

If Gatekeeper still blocks an app, you can remove the quarantine flag for that app bundle manually:

```bash
xattr -dr com.apple.quarantine /Applications/DuckStation.app
```

Repeat the same pattern for `PCSX2.app` or `PPSSPP.app` if needed.

## Run Games

- Double-click a generated launcher in Finder
- Or run it directly from Terminal
- Logs are written to `Logs/`

## Troubleshooting

- `No supported DOSBox binary found.`
  Rerun `./install_emulators_macos.sh` and confirm a DOSBox formula was installed.

- `mGBA was not found.` or similar
  Check that Homebrew installed the formula successfully and that `brew shellenv` is loaded in your shell profile.

- Finder does not execute `.sh` files directly
  Run them from Terminal, or configure Finder to open shell scripts with Terminal.

- PS1 does not boot
  Verify that `BIOS/scph1001.bin` exists and has the expected `524288` byte size.