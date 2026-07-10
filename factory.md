# factory.md

## Project
name: lab64
type: modding-toolchain
language: bash, python
runtime: none (toolchain only, game runs on SpaghettiKart)

## Description
Lab 64 is a private SpaghettiKart character mod that replaces four racers with custom animal characters (Dalmatian, Yellow Lab, Black Cat, Orange Cat) for local team play on Windows. This repository contains the toolchain: helper scripts for rendering sprites, packaging mods, and validating assets, plus documentation for the manual workflow steps.

## Eval Dimensions
- tooling_completeness: Are all pipeline scripts (render, pack, validate, sync) present, executable, and documented?
- documentation_coverage: Do docs cover setup, controllers, modding workflow, and legal boundaries?
- asset_pipeline_readiness: Can the pipeline render sprites from a .blend file, package into .o2r, and validate the result?
- mod_packaging: Does the packaged .o2r contain correct file structure, naming, and mods.toml metadata?

## Guards
- no_roms: Never commit .z64, .n64, .rom, or other ROM files
- no_nintendo_assets: Never commit extracted Nintendo textures, models, or audio
- no_public_distribution: Never configure for public release or distribution
- no_copyrighted_builds: Never package builds containing copyrighted game assets

## Surfaces
### Mutable
- tools/
- docs/
- assets/characters/*/README.md
- mods/animal-pack/mods.toml
- CLAUDE.md
- ROADMAP.md
- .gitignore
- factory.md

### Fixed
- spec.md
- README.md
- .factory/
