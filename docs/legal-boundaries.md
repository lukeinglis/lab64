# Legal Boundaries

Lab 64 is a private, non-commercial project. These boundaries protect the project and its participants.

---

## Do Not Distribute

The following must NEVER be committed to the repository, shared publicly, or included in any distribution:

- [ ] ROM files (`.z64`, `.n64`, `.v64`, `.rom`)
- [ ] Extracted Nintendo assets (textures, models, audio, data files ripped from the ROM)
- [ ] Packaged builds that include copyrighted game assets
- [ ] SpaghettiKart binaries bundled with ROM-derived content
- [ ] Any file that would make the repository a redistributable version of Mario Kart 64

---

## What CAN Be Committed

The following are safe to store in the repository:

- Custom animal character art (original creations, not derived from Nintendo assets)
- Blender `.blend` files with original models
- Rendered sprite sheets of original characters
- Helper scripts and tooling (`tools/`)
- Documentation (`docs/`)
- Mod metadata files (`mods.toml`)
- Project configuration files
- Reference photos of real animals (for modeling reference)
- Screenshots of original Lab 64 content only (see screenshot policy below)

---

## What MUST NOT Be Committed

Even accidentally, do not commit:

- Any file matching `.z64`, `.n64`, `.v64`, `.rom` extensions
- Files from an `extracted-assets/` directory
- Texture files ripped from the original game
- Audio files from the original game
- SpaghettiKart's own source code (unless forking becomes necessary)
- Any file that contains copyrighted Nintendo intellectual property

The `.gitignore` file enforces exclusion of ROM files and common problematic patterns. However, `.gitignore` is not a complete safeguard. Always review staged files before committing.

---

## Screenshot Policy

- **Private use:** Screenshots of gameplay (including Nintendo track backgrounds) are fine for personal reference and internal documentation
- **Do not post publicly:** Screenshots showing Nintendo IP (tracks, items, original characters) should not be shared on public channels, social media, or public repositories
- **Safe to share:** Screenshots showing only Lab 64 original content (custom animal characters in isolation, tool output, documentation renders)

---

## Private Use Justification

This project operates under private, non-commercial use:

- The mod is used only on the owner's own Windows machines
- No public distribution of any mod files containing copyrighted assets
- No commercial activity (no sales, no subscriptions, no ads)
- The project is a private team side project for casual local play
- SpaghettiKart itself is a legal decompilation project that does not distribute copyrighted assets

### Gray Areas

ROM modding for personal use exists in a legal gray area. The project mitigates risk by:

1. **Never distributing ROMs** or extracted assets
2. **Keeping the repository private** (no public access to mod files that reference copyrighted content)
3. **Separating original art from copyrighted content** (custom animal characters are original creations)
4. **Using SpaghettiKart** (a decompilation, not an emulator distributing copyrighted code)
5. **Not profiting** from the project in any way

---

## Enforcement

### In the Repository

- `.gitignore` excludes ROM files and common problematic patterns
- `tools/validate-mod.sh` checks `.o2r` archives for accidentally included ROM files
- Character briefs and asset specifications reference only original content

### Before Committing

Always run:
```bash
git status
git diff --name-only
```

Review the file list for any ROM files, extracted assets, or copyrighted content before committing.

### Before Sharing

If sharing any project output (screenshots, documentation, mod files):
1. Verify no Nintendo IP is visible
2. Verify no ROM files are included
3. Verify no extracted assets are included
4. When in doubt, do not share
