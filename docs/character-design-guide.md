# Character Design Guide

Research-grounded reference for designing and producing Lab 64 custom characters for SpaghettiKart.

## Sprite Specifications

Each character requires **35 sprites** total:

| Asset | Count | Dimensions | Format | Naming |
|---|---|---|---|---|
| Kart rotation frames | 16 | 64x64 (or 128x128, 256x256) | PNG RGBA | `{char}_kart_frame{NNN}.png` |
| Face selection frames | 17 | 64x64 | PNG RGBA | `{char}_face_{00-16}.png` |
| Portrait icon | 1 | 32x32 | PNG RGBA | `common_texture_portrait_{char}.png` |
| Nameplate | 1 | 64x12 | PNG RGBA | `gTexture{Char}.png` |

All dimensions must be power-of-2 (32, 64, 128, 256), except nameplates which use 64x12. The 16 kart frames cover a full 360° rotation at **22.5° intervals**.

### Kart Frame Rotation Layout

```
Frame 01: 0° (front)
Frame 02: 22.5°
Frame 03: 45°
Frame 04: 67.5°
Frame 05: 90° (right side)
Frame 06: 112.5°
Frame 07: 135°
Frame 08: 157.5°
Frame 09: 180° (back)
Frame 10: 202.5°
Frame 11: 225°
Frame 12: 247.5°
Frame 13: 270° (left side)
Frame 14: 292.5°
Frame 15: 315°
Frame 16: 337.5°
```

SpaghettiKart uses billboarded 2D sprites, not 3D models. The game selects the correct rotation frame based on the camera angle relative to the character.

## Character Visual Notes

### Slot Assignments

| Character | Replaces | Weight Class |
|---|---|---|
| Dalmatian | Donkey Kong | Heavy |
| Yellow Lab | Wario | Heavy |
| Black Cat | Luigi | Medium |
| Orange Cat | Bowser | Heavy |

### Dalmatian

- **Palette**: White body with black spots, red collar
- **Build**: Friendly, athletic — fits heavy weight class (replacing DK)
- **Key details**: Spots should be irregular and natural-looking, not uniform circles. Red collar provides a strong accent color for readability at 64x64. Ears floppy.
- **Silhouette**: Upright posture, distinct from the cats. Broad shoulders to match heavy class proportions.

### Yellow Lab

- **Palette**: Golden/wheat coat, warm tones
- **Build**: Slightly stocky, friendly expression — fits heavy weight class (replacing Wario)
- **Key details**: Coat should read as a warm single tone at small sizes; subtle shading variations only visible at 128x128+. Wide smile. Floppy ears differentiate from Dalmatian silhouette.
- **Silhouette**: Rounder, broader than Dalmatian. Should be distinguishable at a glance in 4-player split-screen.

### Black Cat

- **Palette**: Solid black body, bright green eyes
- **Build**: Sleek, agile — fits medium weight class (replacing Luigi)
- **Key details**: Green eyes are the primary identifier at small sizes. Needs visible outline or rim lighting so the black body doesn't disappear against dark karts/tracks. Pointed ears, slender proportions.
- **Silhouette**: Distinctly smaller and sleeker than the dogs. Pointed ear tips are critical for readability.

### Orange Cat

- **Palette**: Orange body with darker tabby stripes, lighter belly
- **Build**: Fluffy, slightly round — fits heavy weight class (replacing Bowser)
- **Key details**: Tabby stripes should be visible at 64x64 as 2-3 bold dark lines, not fine detail. Mischievous expression (half-closed eyes or smirk). Fluffy tail distinguishes from Black Cat.
- **Silhouette**: Rounder and fluffier than Black Cat. Puffy tail visible in profile views.

## Art Style Guidelines

### N64 Low-Poly Aesthetic

- **Triangle count**: 300-800 per character model
- **Shading**: Flat/cel-shaded — no smooth gradients or PBR materials
- **Colors**: Bold, saturated — must read clearly at 64x64 in 4-player split-screen
- **Outlines**: Rely on silhouette contrast rather than drawn outlines
- **Texture**: Minimal texture detail; let geometry and vertex colors carry the design

### Readability Targets

At 64x64 (actual gameplay size), each character must be identifiable by:
1. **Silhouette** — body shape alone should distinguish dog vs cat, heavy vs medium
2. **Primary color** — white (Dalmatian), gold (Lab), black (Cat), orange (Cat)
3. **Accent feature** — red collar, green eyes, tabby stripes, floppy vs pointed ears

Test by scaling sprites to 64x64 and viewing at 100% — if characters blur together, increase contrast.

## Per-Character Workflow Checklist

For each of the four characters, complete these steps in order:

- [ ] **Model** — Create low-poly mesh in Blender (300-800 triangles)
- [ ] **Rig** — Set up segmented joints for kart sitting pose
- [ ] **Render kart frames** — 16 rotation frames at 22.5° intervals
- [ ] **Render face frames** — 17 selection screen expressions
- [ ] **Review portrait** — 32x32 icon reads clearly at small size
- [ ] **Review faces** — 64x64 expressions are distinct and appealing
- [ ] **Create nameplate** — 64x12 text banner with character name
- [ ] **Pack mod** — Run `tools/pack-character-mod.sh`
- [ ] **Validate** — Run `tools/validate-mod.sh` and verify all checks pass

### Render Commands

```bash
# Render sprites from Blender model
blender --background --python tools/render-character-sprites.py -- \
  --character dalmatian \
  --blend-file assets/characters/dalmatian/dalmatian.blend \
  --rotations 16 \
  --resolution 64

# Package into .o2r mod
tools/pack-character-mod.sh dalmatian assets/characters/dalmatian/sprites

# Validate the packaged mod
tools/validate-mod.sh mods/animal-pack/dalmatian.o2r
```

## Sources

- [SpaghettiKart Custom Characters Guide](https://harbourmasters.github.io/SpaghettiKart/md_docs_2custom-characters.html) — official documentation for character replacement sprite specs, naming conventions, and mod structure
- [The Spriters Resource — Mario Kart 64](https://www.spriters-resource.com/nintendo_64/mariokart64/) — reference sprite sheets showing original MK64 character frame counts, rotation angles, and sprite dimensions
- [The Cutting Room Floor — Mario Kart 64](https://tcrf.net/Mario_Kart_64) — development details including unused sprites, frame counts, and rendering approach used by the original game
- [Racer Ready-Up](https://vinievex.itch.io/racer-ready-up) — community tool for SpaghettiKart character assembly and nameplate generation
