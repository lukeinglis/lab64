# Lab 64 Setup Guide

## Quick-Start Checklist (Team Play Day)

Target: game running in 5 minutes.

1. Connect ROG Ally to TV/monitor via USB-C dock (HDMI + USB-A ports)
2. Plug in 8BitDo 2.4G dongles (one per controller)
3. Turn on controllers
4. Launch SpaghettiKart
5. Verify mods loaded (custom characters visible in character select)
6. Select characters and race

---

## SpaghettiKart Installation (Windows)

### 1. Download SpaghettiKart

Download the latest Windows release from the [SpaghettiKart GitHub releases](https://github.com/HarbourMasters/SpaghettiKart/releases) page.

Extract to a known location, e.g. `C:\Games\SpaghettiKart\`.

### 2. Provide the ROM

SpaghettiKart requires a US Mario Kart 64 ROM in `.z64` format.

**Required SHA-1 hash:** `579C48E211AE952530FFC8738709F078D5DD215E`

To verify the hash on Windows (PowerShell):
```powershell
Get-FileHash .\your-rom.z64 -Algorithm SHA1
```

If the ROM is in `.n64` format, it must be converted to `.z64` first. Conversion tools are available in the SpaghettiKart community.

**Place the ROM in the SpaghettiKart directory.** SpaghettiKart will detect it on first launch.

### 3. First Launch

Run `SpaghettiKart.exe`. On first launch it will:
- Detect the ROM file
- Generate required assets
- Open the main menu

If the game does not launch, check:
- ROM format is `.z64` (not `.n64` or `.v64`)
- SHA-1 hash matches the expected value
- Windows Defender or antivirus is not blocking the executable

---

## ROG Ally Setup

### Display Output

The ROG Ally requires a USB-C dock or hub to output to a TV/monitor:

- **Required:** USB-C dock with HDMI output and power passthrough
- **Required:** Enough USB-A ports for controller dongles (4 for 4-player)
- **Recommended:** USB-C dock with at least 4 USB-A ports + HDMI + power

### Armoury Crate Configuration

1. Open Armoury Crate SE on the ROG Ally
2. Set performance mode to **Turbo** for best frame rates
3. Ensure the display is set to mirror/extend to the external monitor
4. Create a game profile for SpaghettiKart if needed

### Power

Keep the ROG Ally plugged in during play sessions. Racing games drain the battery quickly.

---

## macOS Development Environment

Development (modeling, scripting, documentation) happens on macOS. Runtime testing happens on Windows.

### Required Software

- **Blender** (latest stable): Download from [blender.org](https://www.blender.org/download/)
- **Git**: Install via Homebrew (`brew install git`) or Xcode command line tools
- **Python 3**: Comes with macOS or install via Homebrew
- **Text editor**: VS Code, Vim, or preferred editor

### Clone the Repository

```bash
git clone git@github.com:your-org/lab64.git
cd lab64
```

---

## Mod Loading

### Installing Mods

1. Build mods using the asset pipeline (see [modding-notes.md](modding-notes.md))
2. Copy `.o2r` files to SpaghettiKart's `mods/` folder on Windows:
   ```
   C:\Games\SpaghettiKart\mods\
   ```
3. Launch SpaghettiKart; mods load automatically

Use `tools/sync-to-windows.sh` to transfer mods from macOS to Windows.

### Verifying Mods Loaded

- Custom characters should appear in the character select screen
- If characters do not appear, check the mod file is a valid `.o2r` archive
- Run `tools/validate-mod.sh` on the `.o2r` file to check for errors

### Disabling Mods

Rename the `.o2r` file to `.o2r.disabled` to skip it during loading without deleting it.

---

## Troubleshooting

### Game runs too fast in 4-player mode

SpaghettiKart may run at incorrect frame timing in split-screen modes. Check the SpaghettiKart settings for frame rate or V-Sync options.

### Controller interference

Multiple 8BitDo controllers sharing the same dongle channel can cause input conflicts. See [controller-testing.md](controller-testing.md) for pairing procedures.

### Post-race crashes

Some mod configurations can cause crashes after race results. If this happens:
1. Disable all mods
2. Re-enable one at a time to identify the problem mod
3. Run `tools/validate-mod.sh` on the problem mod

### Mod does not appear in game

- Verify the `.o2r` file is in the SpaghettiKart `mods/` folder
- Verify the archive contains a `mods.toml` file at the root
- Check that image files are PNG, JPG, or BMP format
- Check that texture dimensions are correct (see CLAUDE.md for specs)

### Display not detected on ROG Ally

- Try a different HDMI cable or port on the dock
- Restart the ROG Ally with the dock connected
- Check Windows display settings for the external monitor
