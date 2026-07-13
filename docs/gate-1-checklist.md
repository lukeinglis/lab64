# Gate 1 Checklist

Step-by-step guide to verify SpaghettiKart runs, loads mods, and supports 4-player local play — the prerequisites before starting custom character development.

## Prerequisites

| Requirement | Details |
|---|---|
| Windows machine | SpaghettiKart runs natively on Windows |
| N64 ROM | SHA-1: `579C48E211AE952530FFC8738709F078D5DD215E` |
| Controllers | 8BitDo controllers (4x for local multiplayer) |
| Disk space | ~500 MB for SpaghettiKart + ROM + mods |

## Downloads

| Software | Source | Notes |
|---|---|---|
| SpaghettiKart | [GitHub Releases](https://github.com/HarbourMasters/SpaghettiKart) | **Use nightly build, not stable release** — nightly has mod support improvements and bug fixes needed for character mods |
| Racer Ready-Up | [itch.io](https://vinievex.itch.io/racer-ready-up) | Optional. Windows/Linux. Helper tool for character mod assembly with built-in nameplate generator |
| Test mod | [Thunderstore](https://thunderstore.io/c/spaghetti-kart/) or [GameBanana](https://gamebanana.com/games/22970) | Any character replacement mod for testing (e.g., Link by Hato) |

> **Why nightly?** Stable releases may lag behind on mod system features. The nightly build includes the latest mod loading improvements and custom character support. If a nightly build is broken, try the previous day's build.

## Test Steps

Complete each step in order. Do not proceed past a failing step.

### Step 1: Install SpaghettiKart (issue #3)

1. Download the latest **nightly** build from GitHub
2. Extract to a permanent location (e.g., `C:\Games\SpaghettiKart\`)
3. Launch `SpaghettiKart.exe`
4. Verify the title screen appears

**Expected**: SpaghettiKart launches and shows the title screen with a ROM prompt.

**If it fails**:
- Check Windows Defender hasn't quarantined the executable
- Ensure you downloaded the nightly, not the stable release
- Try running as administrator

### Step 2: Load ROM and verify base game (issue #3)

1. Point SpaghettiKart to your N64 ROM file
2. Verify the ROM hash matches: `579C48E211AE952530FFC8738709F078D5DD215E`
3. Start a single-player Grand Prix race
4. Complete at least one full race

**Expected**: Game plays normally — character select works, race starts, AI opponents race, finish line triggers results screen.

**If it fails**:
- Wrong ROM hash → the ROM is the wrong version or region. You need the US v1.0 ROM.
- Black screen after ROM load → try a different nightly build
- Crashes during race → note the track name and report to SpaghettiKart Discord

### Step 3: Test controllers for 4-player (issue #4)

1. Connect all four 8BitDo controllers
2. Open SpaghettiKart controller settings
3. Map each controller to a player slot (P1-P4)
4. Start a 4-player local multiplayer race
5. Verify all four players can steer and use items independently

**Expected**: All four controllers are recognized, mapped correctly, and work simultaneously in a 4-player split-screen race.

**If it fails**:
- 8BitDo controllers may need firmware updates — check [8BitDo support](https://support.8bitdo.com/)
- Try switching controller mode (XInput vs DirectInput)
- Verify controllers work in other games first to isolate the issue
- SpaghettiKart may need controller remapping — check the in-game settings

### Step 4: Test mod loading with a community mod (issue #5)

1. Download a character replacement mod from [Thunderstore](https://thunderstore.io/c/spaghetti-kart/) or [GameBanana](https://gamebanana.com/games/22970)
   - Recommended: any simple character skin mod (e.g., Link mod by Hato — 635+ downloads, well-tested)
2. Place the `.o2r` (or `.zip`) file in SpaghettiKart's `mods/` directory
3. Launch SpaghettiKart
4. Navigate to character select
5. Verify the modded character appears in the replaced slot
6. Race with the modded character

**Expected**: The mod loads without errors, the replacement character appears on the character select screen, and racing with the character works normally.

**If it fails**:
- Verify the mod file is in the correct `mods/` folder (same directory as the executable)
- Check the mod has a valid `mods.toml` file
- Try a different mod to rule out a broken mod file
- Check SpaghettiKart console output for error messages

### Step 5: Run feasibility check (issue #6)

1. On your development machine (macOS/Linux), run:
   ```bash
   tools/check-feasibility.sh
   ```
2. Review the output for all checks

**Expected**: All feasibility checks pass — Blender is installed, required tools are available, directory structure is correct.

**If it fails**:
- Install missing dependencies listed in the output
- Ensure Blender is installed and accessible from the command line
- Check that the project repository is fully cloned (not a shallow clone)

### Step 6: Evaluate Racer Ready-Up tool (issue #7)

1. Download [Racer Ready-Up](https://vinievex.itch.io/racer-ready-up) from itch.io
2. Launch the tool on Windows
3. Explore the interface:
   - Try the built-in nameplate generator
   - Check what file organization features it provides
   - Note any limitations or requirements
4. Document findings for pipeline decisions

**Expected**: The tool runs and provides useful features for character mod assembly. Note whether it handles all our needs or if we need custom tooling for some steps.

**Note**: Racer Ready-Up requires a **nightly** SpaghettiKart build. It may not work with stable releases.

## Gate 1 Pass Criteria

All six steps must pass before proceeding to character modeling:

- [ ] SpaghettiKart launches on Windows
- [ ] Base game plays correctly with the ROM
- [ ] All four 8BitDo controllers work in 4-player split-screen
- [ ] At least one community mod loads and works correctly
- [ ] `check-feasibility.sh` passes all checks
- [ ] Racer Ready-Up evaluated (pass = it works, or we have a documented alternative)

## Links

| Resource | URL |
|---|---|
| SpaghettiKart GitHub | https://github.com/HarbourMasters/SpaghettiKart |
| SpaghettiKart Docs | https://harbourmasters.github.io/SpaghettiKart/ |
| Custom Characters Guide | https://harbourmasters.github.io/SpaghettiKart/md_docs_2custom-characters.html |
| Thunderstore (SK mods) | https://thunderstore.io/c/spaghetti-kart/ |
| GameBanana (MK64 mods) | https://gamebanana.com/games/22970 |
| SpaghettiKart Discord | https://discord.com/invite/shipofharkinian |
| Racer Ready-Up | https://vinievex.itch.io/racer-ready-up |
| 8BitDo Support | https://support.8bitdo.com/ |

## Troubleshooting

### Wrong ROM hash
The ROM must be the **US v1.0** release with SHA-1 `579C48E211AE952530FFC8738709F078D5DD215E`. Other regions (JP, EU) or versions (v1.1) will not work. Use a SHA-1 hash checker to verify your ROM before troubleshooting further.

### Nightly vs stable build
Always use the **nightly** build for mod development. The stable release may not support all mod features. If a nightly is broken, try the previous day's build rather than falling back to stable.

### Mod loading order
SpaghettiKart loads mods in dependency order. If you have multiple mods that replace the same character slot, the last one loaded wins. Check `mods.toml` for dependency declarations. When testing a single mod, remove all other mods from the `mods/` folder to avoid conflicts.

### Controller mapping issues
8BitDo controllers support multiple modes (XInput, DirectInput, Switch, macOS). For SpaghettiKart on Windows, **XInput mode** is usually the best choice. Hold the correct button combination while powering on to select the mode — check your specific 8BitDo model's manual.

### SpaghettiKart crashes on launch
- Disable antivirus / Windows Defender real-time scanning for the SpaghettiKart directory
- Ensure Visual C++ Redistributable is installed
- Try running from a path without spaces or special characters
