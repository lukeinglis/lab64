# Black Cat

## Character Brief

| Field | Value |
|---|---|
| Animal Type | Cat (domestic shorthair, black) |
| Visual Identity | Solid black coat, bright green eyes, sleek build |
| Distinguishing Features | Green eyes that pop against dark fur, upright pointed ears, long tail |
| Target Racer Slot | TBD (owner to confirm; default assumption: Peach) |

## Design Notes

- **Split-screen readability:** Solid black is tricky at small sizes. Use bright green eyes and a colored collar (green or purple) to ensure readability. Consider a subtle dark gray highlight on edges so the silhouette doesn't disappear against dark backgrounds.
- **First-pass goal:** A clear black cat racer. Sleek and slightly mysterious.
- **Silhouette:** Slimmer than the dogs, pointed ears, visible tail. Should read as "cat" instantly.
- **Palette:** Black body, bright green eyes, optional green or purple collar accent, pink inner ears.

## Required Assets

| Asset | Dimensions | Filename Pattern |
|---|---|---|
| Kart frames | 64x64 | `black_cat_kart_frame{NNN}.png` |
| Portrait | 32x32 | `common_texture_portrait_black_cat.png` |
| Selection faces | 64x64 (x17) | `black_cat_face_{00-16}.png` |
| Nameplate | 64x12 | `gTextureBlackCat.png` |

## Blender Model Target

- 300-800 triangles
- Segmented joints (no smooth deformation)
- Low-poly N64 aesthetic
- Vertex coloring for shadow/highlight detail
- Edge highlights to maintain readability against dark tracks
