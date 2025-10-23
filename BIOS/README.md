# BIOS Files

Some emulations like PS1 and PS2 require BIOS files from the original device to function properly. PS3 uses firmware files instead of traditional BIOS.

### How to Dump a PS1 BIOS
1. You need a PS1 console and a way to dump the BIOS
2. Use tools like a modchip or special software to extract the BIOS
3. The BIOS file should be exactly 512KB (524,288 bytes)

### BIOS Filename
- BIOS FIles for all ROMS [`Download`](https://coolrom.com.au/bios/psx/)
- NTSC-U: [`scph1001.bin`](https://duckduckgo.com/?q=PS1+BIOS+scph1001.bin+download&t=h_&ia=web)
- NTSC-J: [`scph1000.bin`](https://duckduckgo.com/?q=PS1+BIOS+scph1000.bin+download&t=h_&ia=web)
- PAL: [`scph1002.bin`](https://duckduckgo.com/?q=PS1+BIOS+scph1002.bin+download&t=h_&ia=web)

## Installation
1. Place your dumped BIOS file in this `BIOS/` folder
2. Rename it to `scph1001.bin` (or appropriate region filename)
3. Run `./install_emulators.sh` to configure DuckStation