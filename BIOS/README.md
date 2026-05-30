# BIOS Files

Some emulators need BIOS files from the original hardware to boot games correctly.

## PS1 BIOS

The recommended PS1 BIOS file names are:

- `scph1001.bin` for NTSC-U
- `scph1000.bin` for NTSC-J
- `scph1002.bin` for PAL

The file should be exactly `524288` bytes (`512 KB`).

## How to Prepare It

1. Dump the BIOS from hardware you own.
2. Copy the BIOS file into this `BIOS/` directory.
3. Rename it to the expected region filename if needed.
4. Run the installer for your platform or follow the platform setup guide:
	- Debian/Ubuntu: `./install_emulators.sh`
	- Fedora: `./install_emulators_fedora.sh`
	- macOS: `./install_emulators_macos.sh`
	- Windows: see `WINDOWS_SETUP.md`

## Notes

- Linux installers configure DuckStation to scan this project `BIOS/` folder automatically.
- On macOS and Windows, DuckStation or PCSX2 may ask you to confirm the BIOS location on first launch.
- If PS1 games fail to boot, verify the filename and size before changing launcher settings.