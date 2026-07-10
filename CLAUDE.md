# Lab 64

## Project Context
Lab 64 is a private SpaghettiKart character mod. SpaghettiKart is a native cross-platform port of Mario Kart 64 (not an emulator), built on libultraship. The mod replaces four existing racer slots with custom animal characters for local team play.

Mario Kart 64 uses billboarded 2D sprites for characters, not 3D models. The asset pipeline renders low-poly Blender models into 2D sprite sequences, then packages them as .o2r mods.

## SpaghettiKart Conventions

### Mod Format
- Mods are `.o2r` files (renamed `.zip` archives)
- Every mod requires a `mods.toml` file at the root
- Mods are placed in SpaghettiKart's `mods/` folder
- Dependency-ordered loading; later mods override earlier ones
- Supported image formats: PNG, JPG, BMP

### Character File Naming
- Kart animation frames: `{character}_kart_frame{NNN}.png` (e.g. `dalmatian_kart_frame001.png`)
- Portrait icon (32x32): `common_texture_portrait_{character}.png`
- Player selection faces (64x64): `{character}_face_{00-16}.png` (17 frames)
- Nameplate (64x12): `gTexture{Character}.png` (capitalized)

### Texture Dimensions
- All textures must be power-of-2 dimensions: 32, 64, 128, 256
- Portrait: 32x32
- Selection faces: 64x64
- Kart frames: 64x64 (can be 128x128 or 256x256)
- Nameplate: 64x12

### Character Directory Structure
```
character_folder/
  character_kart/
    character_kart_frame001.png
    character_kart_frame002.png
    ...
  common_texture_portrait_character.png
  character_face_00.png through character_face_16.png
  gTextureCharacter.png
```

## Asset Pipeline
1. Model character in Blender (300-800 triangles, segmented joints)
2. Render sprites: `blender --background --python tools/render-character-sprites.py -- [args]`
3. Package mod: `tools/pack-character-mod.sh [character] [sprite-dir]`
4. Validate: `tools/validate-mod.sh mods/animal-pack/character.o2r`
5. Transfer: `tools/sync-to-windows.sh` to copy .o2r to Windows machine

## Legal Boundaries
- Never commit ROM files (.z64, .n64, .rom)
- Never commit extracted Nintendo assets
- Never commit packaged builds with copyrighted content
- Custom animal art, scripts, and documentation are safe to commit
- No screenshots showing Nintendo IP in public channels
- Private use only, no public distribution

## Characters
| Character | Animal | Notes |
|---|---|---|
| Dalmatian | Dog | Black spots on white, red collar |
| Yellow Lab | Dog | Golden coat, friendly expression |
| Black Cat | Cat | Solid black, bright green eyes |
| Orange Cat | Cat | Orange tabby stripes, mischievous |

## Commands
- `blender --background --python tools/render-character-sprites.py -- --character dalmatian --blend-file assets/characters/dalmatian/dalmatian.blend`
- `tools/pack-character-mod.sh dalmatian assets/characters/dalmatian/sprites`
- `tools/validate-mod.sh mods/animal-pack/dalmatian.o2r`
- `tools/check-feasibility.sh`

## Key References
- SpaghettiKart: https://github.com/HarbourMasters/SpaghettiKart
- SpaghettiKart docs: https://harbourmasters.github.io/SpaghettiKart/
- Custom characters guide: https://harbourmasters.github.io/SpaghettiKart/md_docs_2custom-characters.html
- Racer Ready-Up tool: https://vinievex.itch.io/racer-ready-up
- ROM SHA-1: 579C48E211AE952530FFC8738709F078D5DD215E
