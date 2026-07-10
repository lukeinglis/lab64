# Lab 64 Spec v2.1

## 1. Overview

**Lab 64** is a private, non-commercial team racing mod built on top of **SpaghettiKart**, reimagining the Mario Kart 64-style experience with custom team-inspired racers, custom visuals, and eventually custom office-themed tracks.

The project is not intended to be distributed publicly or sold commercially. It is a fun side project for local team play, designed to run on one of the owner's Windows machines, such as an ASUS ROG Ally or another Windows machine, connected to a shared display.

The first version should focus on getting the SpaghettiKart setup working reliably, validating controller support, and replacing a small set of existing racers with simple animal characters. Custom 3D tracks should come after the character mod workflow is proven.

## 2. One-Sentence Pitch

**Lab 64 is a private Mario Kart 64-style team racing mod where players race as custom animal characters through existing tracks first, then eventually through miniature office-themed custom tracks.**

This pitch may evolve as the project develops and the customization possibilities become clearer.

## 3. Project Goals

The project should:

- Create a fun, competitive, local multiplayer racing game for team breaks, offsites, and casual events.
- Use SpaghettiKart as the racing foundation instead of building a new engine from scratch.
- Replace selected existing racers with custom animal racers.
- Keep the first version simple enough to actually complete.
- Preserve the core Mario Kart 64-style feel: split-screen racing, items, laps, cups, and chaos.
- Eventually add a custom office-themed 3D track with miniature racers moving through a stylized workplace.
- Run locally on the owner's Windows machines.
- Avoid distributing ROMs, extracted Nintendo assets, or packaged builds containing copyrighted game assets.

## 4. Non-Goals

The MVP should not include:

- Building a custom racing engine.
- Recreating driving physics from scratch.
- Publishing the mod publicly.
- Selling or commercializing the project.
- Distributing a ROM.
- Distributing extracted Nintendo-owned assets.
- Replacing every racer immediately.
- Creating a custom track before the character workflow is proven.
- Adding online multiplayer.
- Creating custom items.
- Rebalancing racer stats.
- Creating perfect likenesses of real team pets in the first pass.

## 5. Implementation Direction

**Lab 64 will use SpaghettiKart as the foundation.**

This spec assumes SpaghettiKart is the implementation path. The project is a modding and customization project rather than a ground-up game development project.

The project should rely on SpaghettiKart for:

- Race engine
- Kart handling
- Split-screen multiplayer
- Items
- Laps and race rules
- Existing tracks
- Existing menus, unless later modified
- Controller input, assuming validation succeeds

## 6. Target Platform

### Development

- Primary development machine: macOS.
- Asset editing tools: TBD.
- Version control: GitHub.

### Runtime

- Primary runtime: Windows.
- Primary device: ASUS ROG Ally or another Windows machine owned by the project owner.
- Display: TV, monitor, or conference room screen.
- Input: 8BitDo 2.4G controllers connected through USB dongles.
- Hardware support: USB-C dock or hub with HDMI, power passthrough, and enough USB-A ports for controller dongles.

The project can be developed primarily on macOS, but gameplay testing and hosting should happen on the ASUS ROG Ally or another Windows machine because of controller compatibility.

## 7. Legal and Distribution Boundaries

Lab 64 is a private, non-commercial project.

The project should follow these boundaries:

- Do not distribute ROM files.
- Do not distribute extracted Nintendo assets.
- Do not distribute packaged builds that include copyrighted game assets.
- Keep custom mod files separate from any ROM-derived files.
- Run the project only on the owner's own Windows machines.
- Treat the project as a private team side project, not a public release.

Custom-created assets, such as animal character art or original office track models, may be stored in the project repository if they do not include copyrighted source assets.

## 8. MVP Strategy

The MVP should not start with a custom track.

The first milestone should be a **character replacement pack** that works on existing tracks.

This lets the project prove the core workflow before taking on harder custom 3D track work.

### MVP Name

**Lab 64: Animal Pack**

### MVP Scope

The MVP should include:

- Working SpaghettiKart setup on Windows.
- Confirmed controller support.
- Confirmed local multiplayer support.
- Four animal character replacements.
- Existing Mario Kart 64 tracks.
- Existing items and race modes.
- Simple documentation for how to launch and play.

## 9. Feasibility Test

Before full production, complete a feasibility test.

### Goal

Confirm that SpaghettiKart can support the desired private team setup.

### Feasibility Checklist

The feasibility test is successful if:

- SpaghettiKart launches on a Windows machine.
- The owner's ROM works with the setup.
- The game runs smoothly.
- One gifted 8BitDo controller works.
- Two gifted controllers work at the same time.
- Four-player local multiplayer works, or appears achievable.
- The setup works on the ROG Ally.
- The ROG Ally can output to a shared display.
- Controller mapping is stable enough for repeated use.
- A simple existing mod or test mod can be loaded.
- A small visual replacement can be tested.

### Decision Gate

If the feasibility test passes, move into the character replacement workflow.

If it fails, troubleshoot the specific blocker before expanding scope.

## 10. MVP Character Roster

The first character pack should include four simple animal racers:

| Lab 64 Racer | Animal Type | First-Pass Goal |
|---|---|---|
| Dalmatian | Dog | Clear Dalmatian-inspired racer |
| Yellow Lab | Dog | Clear yellow Labrador-inspired racer |
| Black Cat | Cat | Clear black cat-inspired racer |
| Orange Cat | Cat | Clear orange cat-inspired racer |

### Character Philosophy

The first pass should focus on readability and fun, not perfect realism.

Each character should be:

- easy to identify in split screen,
- visually distinct from the others,
- recognizable as the intended animal,
- simple enough to create without blocking the project.

### Character Stats

The MVP should not rebalance stats.

Characters should inherit the behavior of the racer slot they replace, unless there is an easy way to normalize stats without creating extra complexity.

The first goal is visual replacement, not gameplay rebalance.

## 11. Character Replacement Strategy

The project should replace existing racer slots rather than adding brand-new racer slots, unless adding new slots proves simple and reliable.

### First-Pass Approach

Start with one character replacement before attempting all four.

Recommended order:

1. Replace one racer with a rough animal placeholder.
2. Confirm the character appears correctly in menus and races.
3. Confirm the character is readable in split-screen gameplay.
4. Confirm no major animation or texture issues.
5. Repeat for the remaining three characters.

### Character Asset Priorities

For each animal racer, prioritize:

1. In-race appearance
2. Character select appearance
3. Portrait/icon
4. Name text
5. Voice or sound replacement, if feasible later

## 12. Gameplay

Since Lab 64 uses SpaghettiKart as the foundation, the MVP should rely on existing gameplay systems.

### MVP Gameplay Includes

- Existing racing modes.
- Existing items.
- Existing split-screen multiplayer.
- Existing lap counts.
- Existing cups/tracks.
- Existing race rules.
- Existing battle/race behavior unless later customized.

### Gameplay Customization

The MVP should avoid deep gameplay changes.

Do not attempt to change:

- item behavior,
- kart physics,
- race rules,
- lap logic,
- AI behavior,
- collision systems,
- camera behavior,
- or rubber-banding.

Those systems can be revisited later if modding support makes them accessible and the team wants deeper customization.

## 13. First Custom Track

The first custom track should come after the character pack is working.

### Track Name

**Office Circuit**

### Track Concept

**Office Circuit** is a custom 3D track where miniature racers speed through an oversized office environment.

The track should feel like the racers are tiny animals racing through a stylized version of a team workspace.

The course should include multiple office zones, with the game room and ping pong table as one memorable section rather than the entire track.

### Track Fantasy

Tiny racers tear through an office, weave around desks and chairs, cut through a game room, pass the ping pong table, and loop back through a workplace-themed course built for split-screen chaos.

## 14. Office Circuit Track Sections

The first custom track may include the following sections:

### 1. Starting Grid / Office Floor

- Start line on the office floor.
- Wide opening stretch.
- Simple first turn.
- Clear visibility for all players.

### 2. Desk Zone

- Desks as large scenery objects.
- Keyboard keys as curb-like details.
- Coffee mugs, notebooks, and sticky notes as scale markers.
- Cables as possible boundaries or hazards.

### 3. Conference Area

- Table legs and chair wheels as obstacles or scenery.
- Wider corner or hairpin around a meeting table.
- Water bottles, notebooks, or laptop props.

### 4. Game Room

- A more playful section of the track.
- Includes the ping pong table as the visual centerpiece.
- May include paddles, ping pong balls, and game room furniture.

### 5. Ping Pong Table Feature

The ping pong table should be a memorable track moment.

Possible designs:

- Racers drive around the ping pong table legs.
- Racers briefly drive onto part of the table.
- A ramp sends racers onto or across the table.
- The net acts as a visual obstacle.
- A gap in the net creates a route.
- A shortcut cuts through the game room section.

### 6. Return Stretch

- Final straightaway back towards the start/finish line.
- Good place for item chaos and last-second overtakes.
- Should be readable in split screen.

## 15. Office Circuit Design Principles

The first custom track should be simple, readable, and achievable.

### Track Should Have

- A clear route.
- Strong office identity.
- A game room / ping pong section.
- Good split-screen readability.
- Wide enough roads for multiplayer.
- Clear walls and boundaries.
- Clear lap/checkpoint behavior.
- A few memorable props.
- One signature moment.

### Track Should Avoid at First

- Too many shortcuts.
- Complex verticality.
- Confusing intersections.
- Tight hallways that cause constant crashes.
- Jumps that break lap counting.
- Moving hazards.
- Overly detailed scenery that hurts readability.
- Routes that are hard to validate in the modding workflow.

## 16. Track Progression

Custom track development should happen in stages.

### Track Prototype 1: Graybox Office Circuit

Goal: prove the custom track works.

Includes:

- basic road layout,
- simple walls,
- start/finish,
- lap validation,
- no detailed office art.

### Track Prototype 2: Office Props

Goal: make the track feel like an office.

Add:

- desks,
- chairs,
- tables,
- keyboard shapes,
- coffee mugs,
- sticky notes,
- basic game room props.

### Track Prototype 3: Ping Pong Section

Goal: add the signature section.

Add:

- ping pong table,
- table legs,
- paddles,
- balls,
- optional route around or onto the table.

### Track Prototype 4: Polish

Goal: make it feel team-ready.

Add:

- better textures,
- readable signs,
- route markers,
- visual polish,
- final collision cleanup,
- final split-screen testing.

## 17. Team Play Setup

Because this is intended for casual team play, the setup should become repeatable.

### Setup Documentation Should Include

- Which Windows machine to use.
- Where SpaghettiKart is installed.
- Where mods are placed.
- How to launch Lab 64.
- How to connect controllers.
- Which controller maps to which player.
- How to connect to a TV or conference room screen.
- Known troubleshooting steps.

### Team Play Success Criteria

The setup is successful when:

- The game can be launched in a few minutes.
- Controllers connect without major troubleshooting.
- 2-player local multiplayer works.
- 4-player local multiplayer works if enough controllers are available.
- The game is readable on the shared screen.
- Players can start racing without needing technical explanations.

## 18. Repository Strategy

Lab 64 should start as a blank private GitHub repository, not as a fork of SpaghettiKart.

The Lab 64 repository should contain only project-specific materials, such as:

- spec files,
- setup documentation,
- controller testing notes,
- modding notes,
- custom-created character assets,
- custom-created track assets,
- custom mod files,
- screenshots or references that are safe to store,
- helper scripts or tooling created for the project.

A fork of SpaghettiKart should only be created later if the project needs to modify SpaghettiKart source code directly.

### Recommended Repository Structure

```text
lab-64/
  README.md
  spec.md
  docs/
    setup.md
    controller-testing.md
    modding-notes.md
  assets/
    characters/
      dalmatian/
      yellow-lab/
      black-cat/
      orange-cat/
    tracks/
      office-circuit/
  mods/
    animal-pack/
    office-circuit/
  references/
    screenshots/
    inspiration/
  tools/
```

### Repository Boundaries

Do not commit:

- ROM files,
- extracted Nintendo assets,
- packaged playable builds containing copyrighted game assets,
- generated files that include copyrighted source assets,
- anything that would make the repository a redistributable version of the original game.

SpaghettiKart should be cloned, installed, or referenced separately from the Lab 64 repo unless source-level changes become necessary.

## 19. MVP Definition of Done

The MVP is complete when:

- SpaghettiKart runs on a Windows machine owned by the project owner.
- The setup works on the ASUS ROG Ally or another chosen Windows host.
- Development and asset preparation can be managed primarily from macOS where practical.
- At least two gifted 8BitDo controllers work.
- Four-player local multiplayer is validated if enough controllers are available.
- A mod can be loaded reliably.
- At least four racers are replaced with:
  - Dalmatian
  - Yellow Lab
  - Black Cat
  - Orange Cat
- Custom racers are readable during races.
- Existing tracks are playable with the custom racers.
- The setup is private and local.
- The project does not distribute ROMs or copyrighted game assets.
- There is a simple setup guide for launching and playing.
- The team can play a local race and immediately understand the concept.

## 20. Future Expansion

Future features may include:

- Office Circuit custom track.
- Additional team pet racers.
- Custom character portraits.
- Custom racer names.
- Custom title/menu visuals.
- Custom cups.
- More office-themed tracks.
- Game room-focused track sections.
- Team inside jokes.
- Custom sound effects.
- Battle mode customizations.
- A more polished launcher or setup process.

Future features should only be added after the MVP is playable and stable.
