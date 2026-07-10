# Characters

Lab 64 replaces four existing SpaghettiKart racer slots with custom animal characters.

## Character Roster

| Character | Animal | Visual Identity | Racer Slot |
|---|---|---|---|
| [Dalmatian](dalmatian/README.md) | Dog | White with black spots, red collar | TBD |
| [Yellow Lab](yellow-lab/README.md) | Dog | Golden coat, friendly expression | TBD |
| [Black Cat](black-cat/README.md) | Cat | Solid black, bright green eyes | TBD |
| [Orange Cat](orange-cat/README.md) | Cat | Orange tabby stripes, mischievous | TBD |

## Design Philosophy

- **Readability over realism:** Characters must be identifiable in 4-player split-screen at small sizes
- **Visual distinction:** Each character should be instantly distinguishable from the others by color and silhouette
- **N64 aesthetic:** Low-poly models (300-800 triangles), 32x32 and 64x64 textures, vertex coloring
- **Fun over perfect:** First-pass characters target "clear and fun," not photorealistic pet likenesses

## Development Order

Build and test characters one at a time:

1. **Dalmatian** (recommended first, high-contrast spots are easy to validate)
2. **Yellow Lab**
3. **Black Cat**
4. **Orange Cat**

Test each character fully in SpaghettiKart before starting the next. See [docs/modding-notes.md](../../docs/modding-notes.md) for the component isolation testing strategy.

## Directory Structure

Each character directory contains:

```
character-name/
  README.md           Character brief (design notes, asset specs)
  character-name.blend Blender source file (created during modeling)
  sprites/            Rendered sprite output from render-character-sprites.py
    character_kart/   Kart animation frames
    *.png             Portrait, faces, nameplate
```

## Asset Requirements

See individual character READMEs for specific file naming patterns. All characters share the same requirements:

- 16 kart animation frames at 64x64
- 1 portrait at 32x32
- 17 selection face frames at 64x64
- 1 nameplate at 64x12
