# Lab 64 Roadmap

## Gate 1: Feasibility Test

**Goal:** Confirm SpaghettiKart can support the desired private team setup.

**Checklist:**
- [ ] SpaghettiKart launches on Windows machine
- [ ] Owner's ROM works with the setup (SHA-1: `579C48E211AE952530FFC8738709F078D5DD215E`)
- [ ] Game runs smoothly (no major frame drops)
- [ ] One 8BitDo controller works
- [ ] Two 8BitDo controllers work simultaneously
- [ ] Four-player local multiplayer works (or appears achievable)
- [ ] ROG Ally can output to shared display via USB-C dock
- [ ] Controller mapping is stable for repeated use
- [ ] A simple existing mod loads successfully
- [ ] A small visual replacement can be tested
- [ ] Asset pipeline scripts run without errors

**DO NOT PROCEED to Gate 2 if:**
- SpaghettiKart fails to launch or crashes consistently
- ROM cannot be validated
- No controller works with the setup
- Mod loading system does not function
- Display output from ROG Ally is not viable

**Run:** `tools/check-feasibility.sh` to walk through the checklist interactively.

---

## Gate 2: Animal Pack MVP

**Goal:** Four custom animal characters working in local multiplayer.

**Prerequisites:** Gate 1 passed.

**Checklist:**
- [ ] Dalmatian character modeled, rendered, packaged, and tested in-game
- [ ] Yellow Lab character modeled, rendered, packaged, and tested in-game
- [ ] Black Cat character modeled, rendered, packaged, and tested in-game
- [ ] Orange Cat character modeled, rendered, packaged, and tested in-game
- [ ] All four characters visible and readable in split-screen
- [ ] Character select screen shows all four replacements correctly
- [ ] No animation or texture glitches during races
- [ ] Setup guide written and tested (5-minute launch target)
- [ ] At least one successful team play session completed

**DO NOT PROCEED to Gate 3 if:**
- Any character causes crashes or visual corruption
- Split-screen readability is poor (characters look identical or unrecognizable)
- Controller issues remain unresolved
- No team play session has happened

**Character development order:** One character at a time. Fully test before starting the next.

---

## Gate 3: Office Circuit Custom Track

**Goal:** A custom office-themed track playable with the Animal Pack characters.

**Prerequisites:** Gate 2 passed AND at least one team play session completed.

**Checklist:**
- [ ] OverKart 64 tooling researched and tested
- [ ] Graybox track layout with road, walls, start/finish, and lap validation
- [ ] Office props added (desks, chairs, coffee mugs, keyboards)
- [ ] Ping pong table signature section implemented
- [ ] Track playable in split-screen without visual glitches
- [ ] Lap counting works correctly
- [ ] No stuck spots or collision issues
- [ ] Track integrated into Animal Pack mod

**DO NOT PROCEED if:**
- Gate 2 has not been fully validated
- No team play session has happened with the Animal Pack
- Track creation tooling proves unworkable
