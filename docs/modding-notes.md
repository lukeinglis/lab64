# Modding Notes

## SpaghettiKart Mod System Overview

SpaghettiKart uses a file-based mod system. Mods are archive files placed in the `mods/` folder inside the SpaghettiKart installation directory.

### Mod Formats

| Format | Description |
|---|---|
| `.o2r` | Recommended. Renamed `.zip` archive with mod contents. |
| `.zip` | Standard zip archive. Also supported. |
| Folder | Loose folder with mod contents. Good for development. |
| `.disabled` | Renamed archive that is skipped during loading. |

**Note:** `.otr` archives are NOT supported by SpaghettiKart.

### mods.toml

Every mod requires a `mods.toml` file at the root of the archive. Minimal example:

```toml
[mod]
name = "Lab 64: Dalmatian"
version = "0.1.0"
description = "Custom Dalmatian character replacement."

[mod.authors]
names = ["Lab 64 Team"]
```

### Loading Order

Mods load in dependency order. If Mod A depends on Mod B, B loads first. Later-loaded mods override resources from earlier ones (cascading override system).

---

## Character Replacement Workflow

### Step-by-Step (Using Lab 64 Tools)

1. **Model the character** in Blender (300-800 triangles, segmented joints)

2. **Render sprites** from the Blender model:
   ```bash
   blender --background --python tools/render-character-sprites.py -- \
     --character dalmatian \
     --blend-file assets/characters/dalmatian/dalmatian.blend \
     --rotations 16 \
     --resolution 64
   ```

3. **Review rendered sprites** in `assets/characters/dalmatian/sprites/`

4. **Package the mod:**
   ```bash
   tools/pack-character-mod.sh dalmatian assets/characters/dalmatian/sprites
   ```

5. **Validate the mod:**
   ```bash
   tools/validate-mod.sh mods/animal-pack/dalmatian.o2r
   ```

6. **Transfer to Windows:**
   ```bash
   tools/sync-to-windows.sh mods/animal-pack/dalmatian.o2r
   ```

7. **Test in SpaghettiKart** (launch the game, check character select, race)

### Component Isolation Testing

**Test ONE character at a time.** Do not batch-test all four characters simultaneously on the first attempt.

For each character:
1. Install only that character's `.o2r` mod
2. Launch SpaghettiKart
3. Verify the character appears in the character select screen
4. Start a single-player race and verify the character renders correctly
5. Start a 2-player split-screen race and verify readability
6. Complete a full race (check for post-race crashes)
7. If any issues, fix before moving to the next character

Once all four characters work individually, test all four loaded simultaneously.

---

## Asset Requirements Per Character

Each character replacement requires these files:

| Asset | Count | Dimensions | Naming Pattern |
|---|---|---|---|
| Kart frames | 16 (default) | 64x64 | `{char}_kart_frame{NNN}.png` |
| Portrait | 1 | 32x32 | `common_texture_portrait_{char}.png` |
| Selection faces | 17 | 64x64 | `{char}_face_{00-16}.png` |
| Nameplate | 1 | 64x12 | `gTexture{Char}.png` |

Where `{char}` is the lowercase character name (e.g. `dalmatian`) and `{Char}` is the capitalized version (e.g. `Dalmatian`).

### Character Naming

Use underscore-separated lowercase names for file system compatibility:

| Character | File Name | Capitalized |
|---|---|---|
| Dalmatian | `dalmatian` | `Dalmatian` |
| Yellow Lab | `yellow_lab` | `YellowLab` |
| Black Cat | `black_cat` | `BlackCat` |
| Orange Cat | `orange_cat` | `OrangeCat` |

---

## SpaghettiKart Directory Structure (Windows)

```
C:\Games\SpaghettiKart\
  SpaghettiKart.exe
  mods/
    dalmatian.o2r
    yellow_lab.o2r
    black_cat.o2r
    orange_cat.o2r
  ... (other SpaghettiKart files)
```

Mods can also be combined into a single `.o2r` archive if preferred.

---

## File Naming Conventions

SpaghettiKart expects specific file naming patterns for character replacements. The naming must match the character slot being replaced.

**Kart animation frames:**
```
dalmatian_kart/
  dalmatian_kart_frame001.png
  dalmatian_kart_frame002.png
  ...
  dalmatian_kart_frame016.png
```

**Player selection faces (17 frames):**
```
dalmatian_face_00.png
dalmatian_face_01.png
...
dalmatian_face_16.png
```

**Portrait and nameplate:**
```
common_texture_portrait_dalmatian.png
gTextureDalmatian.png
```

---

## Useful Tools

### Racer Ready-Up

[Racer Ready-Up](https://vinievex.itch.io/racer-ready-up) by VinieVex is a helper tool for SpaghettiKart character assembly:
- Built-in nameplate generator
- Simplifies racer file organization
- Available for Windows and Linux

### Kart Setup Blend File

The SpaghettiKart community provides a Kart Setup `.blend` file that includes:
- Pre-configured kart model with rigging
- Correct scale and proportions
- Animation skeleton for character poses

Download from the SpaghettiKart Discord or modding community.

---

## Resources

- [SpaghettiKart Documentation](https://harbourmasters.github.io/SpaghettiKart/)
- [SpaghettiKart Custom Characters Guide](https://harbourmasters.github.io/SpaghettiKart/md_docs_2custom-characters.html)
- [SpaghettiKart Modding Guide](https://harbourmasters.github.io/SpaghettiKart/md_docs_2modding.html)
- [GameBanana MK64 Hub](https://gamebanana.com/games/6558) (community mods, tutorials, Q&A)
- [Racer Ready-Up Tool](https://vinievex.itch.io/racer-ready-up)

---

## Research Citations

### Official Documentation

- [SpaghettiKart Custom Characters Guide](https://harbourmasters.github.io/SpaghettiKart/md_docs_2custom-characters.html) — primary source for sprite specifications (16 kart frames, 17 face frames, portrait, nameplate), naming conventions, and mod structure requirements

### Community Mod Examples

Published SpaghettiKart character mods that demonstrate the replacement workflow and serve as reference implementations:

| Mod | Author | Downloads | Source |
|---|---|---|---|
| Link | Hato | 635+ | [Thunderstore](https://thunderstore.io/c/spaghetti-kart/) |
| Kris | sitton76 | — | [Thunderstore](https://thunderstore.io/c/spaghetti-kart/) |
| Ralsei | sitton76 | — | [Thunderstore](https://thunderstore.io/c/spaghetti-kart/) |
| Kazz | — | — | [Thunderstore](https://thunderstore.io/c/spaghetti-kart/) |

These mods confirm that the character replacement workflow is proven and that community modders are actively producing and distributing custom characters.

### Racer Ready-Up Tool Evaluation

[Racer Ready-Up](https://vinievex.itch.io/racer-ready-up) by VinieVex:
- **Platforms**: Windows, Linux
- **Features**: Built-in nameplate generator, file organization helper, character assembly workflow
- **Requirement**: Needs a **nightly** SpaghettiKart build (not stable)
- **Evaluation**: Useful for nameplate generation and as a reference for expected file structure. May supplement or partially replace custom pipeline tooling for certain steps.

### Mod Distribution Platforms

- [Thunderstore — SpaghettiKart](https://thunderstore.io/c/spaghetti-kart/) — primary mod distribution platform for SpaghettiKart, includes character skins, gameplay mods, and cosmetics
- [GameBanana — SpaghettiKart](https://gamebanana.com/games/22970) — alternative mod hosting with community ratings and screenshots

### Community

- [SpaghettiKart Discord](https://discord.com/invite/shipofharkinian) — active community for mod development support, sharing work-in-progress, and troubleshooting
