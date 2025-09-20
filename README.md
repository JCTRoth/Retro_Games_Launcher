# DOSBox Launcher

This program creates launcher scripts that allow you to run a DOS game with a single double-click.  
It uses a default `dosbox.conf` located in the `/Configuration` folder.  
If a `dosbox.conf` is present in a program's folder, the launcher will use that configuration instead of the global one.

## Usage

1. **Install DOSBox**  
   - **Windows / macOS:** Install DOSBox globally, or store it in `/Configuration/DosBox`.  
   - **Linux:** No additional installation is required.  

2. **Running Programs**  
   - Run launcher generator scripts.
     **Linux / macOS:** Run `create_launchers.sh`.  
     **Windows:** Run the corresponding `.bat` file.  
     After reloading the folder there will be now the launchers for the programs stored in the Progams folder.  

3. Double click the launch_*YourProgramName*.sh or .bat on windows.
   Your program should start now.


## Folder Structure

```
DOS\_Launcher/
├── Configuration/          # Store in this folder a DosBox Folder with the DoxBox installation.
│   └── dosbox.conf         # Global DOSBox configuration
├── Programs/               # Program folders inside
│   └── Blood/              # Example program
├── create\_launchers.sh    # Script to generate launchers
└── start\_Blood.sh         # Example launcher
```

## Notes/Tipps

- Press ALT + ENTER to jump any time out of the fullscreen mode.
- TODO TEST ON WINDOWS
- Each program folder can include its own `dosbox.conf` to override the global configuration.  
- The launchers handle mounting and starting the DOSBox environment automatically.
