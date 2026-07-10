# Dalmatian

## Character Brief

| Field | Value |
|---|---|
| Animal Type | Dog (Dalmatian) |
| Visual Identity | White coat with black spots, red collar |
| Distinguishing Features | Spotted pattern, floppy ears, athletic build |
| Target Racer Slot | TBD (owner to confirm; default assumption: Mario) |

## Design Notes

- **Split-screen readability:** The high-contrast black-on-white spot pattern should be recognizable even at small sizes. Prioritize large, bold spots over realistic markings.
- **First-pass goal:** A clear Dalmatian-inspired racer, not a photorealistic dog. Readable and fun.
- **Silhouette:** Athletic dog build, distinguishable from the Yellow Lab by ear shape and spot pattern.
- **Palette:** White body, black spots, red collar accent, dark nose/eyes.

## Required Assets

| Asset | Dimensions | Filename Pattern |
|---|---|---|
| Kart frames | 64x64 | `dalmatian_kart_frame{NNN}.png` |
| Portrait | 32x32 | `common_texture_portrait_dalmatian.png` |
| Selection faces | 64x64 (x17) | `dalmatian_face_{00-16}.png` |
| Nameplate | 64x12 | `gTextureDalmatian.png` |

## Blender Model Target

- 300-800 triangles
- Segmented joints (no smooth deformation)
- Low-poly N64 aesthetic
- Vertex coloring for shadow/highlight detail
