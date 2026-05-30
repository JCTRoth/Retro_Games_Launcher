# Windows Emulator Layout

Place each Windows emulator in its own folder under `Configuration/Emulators`.

Expected subfolders:

- `Configuration/Emulators/DOSBox`
- `Configuration/Emulators/mGBA`
- `Configuration/Emulators/DuckStation`
- `Configuration/Emulators/PCSX2`
- `Configuration/Emulators/PPSSPP`
- `Configuration/Emulators/Mupen64Plus`

The Windows runtime searches each folder for the expected `.exe` first and then falls back to the first `.exe` it finds in that folder.

You can keep emulator archives extracted in these folders as long as the main executable stays inside the matching emulator directory.