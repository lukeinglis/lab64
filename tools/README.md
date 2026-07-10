# Tools

Helper scripts for the Lab 64 asset pipeline and project management.

## Asset Pipeline

### render-character-sprites.py

Blender Python script that renders a character model into the sprite files required by SpaghettiKart.

**Requires:** Blender installed and accessible from the command line.

**Usage:**
```bash
blender --background --python tools/render-character-sprites.py -- \
  --character dalmatian \
  --blend-file assets/characters/dalmatian/dalmatian.blend \
  --rotations 16 \
  --resolution 64 \
  --output-dir assets/characters/dalmatian/sprites
```

**Arguments:**
| Argument | Required | Default | Description |
|---|---|---|---|
| `--character` | Yes | | Character name (e.g. `dalmatian`) |
| `--blend-file` | Yes | | Path to the `.blend` file |
| `--rotations` | No | 16 | Number of rotation angles for kart frames |
| `--resolution` | No | 64 | Pixel resolution for kart frames |
| `--output-dir` | No | `assets/characters/{name}/sprites` | Output directory |

**Output:**
- `{char}_kart/` directory with `{char}_kart_frame{NNN}.png` files
- `common_texture_portrait_{char}.png` (32x32)
- `{char}_face_{00-16}.png` (17 files at 64x64)
- `gTexture{Char}.png` (64x12 nameplate)

---

### pack-character-mod.sh

Packages rendered sprites into a SpaghettiKart `.o2r` mod archive.

**Usage:**
```bash
tools/pack-character-mod.sh dalmatian assets/characters/dalmatian/sprites
```

**What it does:**
1. Validates all required files exist (kart frames, portrait, faces, nameplate)
2. Checks image dimensions match SpaghettiKart requirements
3. Generates a `mods.toml` metadata file
4. Creates the correct directory structure
5. Zips everything into a `.o2r` archive in `mods/animal-pack/`

**Output:** `mods/animal-pack/{character}.o2r`

---

### validate-mod.sh

Validates a `.o2r` mod archive for correctness before deployment.

**Usage:**
```bash
tools/validate-mod.sh mods/animal-pack/dalmatian.o2r
```

**Checks:**
- Archive is a valid zip file
- `mods.toml` exists with required fields (`name`, `version`)
- All images are valid PNG/JPG/BMP format
- Texture dimensions are power-of-2 (32, 64, 128, 256; nameplate height 12 is allowed)
- No ROM files accidentally included
- No `extracted-assets/` directory present
- Reports file count, archive size, warnings, and errors

**Exit codes:** 0 = pass, 1 = validation failure

---

### sync-to-windows.sh

Transfers `.o2r` mod files to a Windows machine running SpaghettiKart.

**Usage:**
```bash
# Using environment variable
export LAB64_WINDOWS_MODS_PATH="user@windows-pc:/c/Games/SpaghettiKart/mods"
tools/sync-to-windows.sh mods/animal-pack/dalmatian.o2r

# Using --target flag with mounted drive
tools/sync-to-windows.sh --target /Volumes/USB/SpaghettiKart/mods mods/animal-pack/*.o2r

# No target configured (prints manual instructions)
tools/sync-to-windows.sh mods/animal-pack/dalmatian.o2r
```

**Transfer methods:**
1. **rsync over SSH** (if target contains `:`, e.g. `user@host:/path`)
2. **Local copy** (if target is a local mount path, e.g. `/Volumes/USB/...`)
3. **Manual instructions** (if no target configured)

If no mod files are specified, syncs all `.o2r` files found in `mods/`.

---

## Project Management

### check-feasibility.sh

Interactive checklist that walks through Gate 1 feasibility items from the project spec.

**Usage:**
```bash
tools/check-feasibility.sh
```

**What it does:**
1. Presents each feasibility item one at a time
2. Accepts pass (p), fail (f), or skip (s) for each item
3. Provides troubleshooting suggestions for failed items
4. Saves results to `docs/feasibility-results.md`
5. Reports overall verdict: PASS, BLOCKED, or INCOMPLETE

**Items tested:**
1. SpaghettiKart launches
2. ROM works
3. Game runs smoothly
4. Single controller works
5. Two controllers work
6. Four-player multiplayer works
7. ROG Ally display output
8. Controller mapping stability
9. Existing mod loads
10. Visual replacement works
11. Pipeline scripts run

Run this before starting character development (Gate 2).
