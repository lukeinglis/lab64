# Controller Testing Guide

## Strategy: Wired First

Always validate controllers with wired USB connections before attempting wireless. This eliminates wireless pairing issues as a variable during initial setup.

---

## 8BitDo 2.4G Controller Setup

### Hardware Required

- 8BitDo 2.4G controllers (one per player)
- 8BitDo USB 2.4G wireless dongles (one per controller)
- USB-C dock/hub with enough USB-A ports for all dongles

### Pairing Steps

1. Plug the 8BitDo 2.4G dongle into a USB-A port on the dock
2. Turn on the controller (the controller pairs automatically with its matched dongle)
3. Verify the controller is recognized in Windows (Settings > Bluetooth & devices > Devices)
4. Open a controller test app or SpaghettiKart to verify input

Each 8BitDo 2.4G controller is pre-paired with its specific dongle. They do not need Bluetooth pairing.

### Single Controller Validation

Before testing multi-controller, validate one controller works:

1. Connect one dongle
2. Power on one controller
3. Open SpaghettiKart
4. Navigate menus with the controller
5. Start a single-player race
6. Verify all inputs: D-pad/analog stick, A (accelerate), B (brake), triggers (items)
7. Complete one full race

### Multi-Controller Testing

After one controller is confirmed working:

1. Connect a second dongle to a different USB-A port
2. Power on the second controller
3. Start a 2-player race in SpaghettiKart
4. Verify each controller maps to a separate player
5. Verify no input crosstalk between controllers
6. Repeat for 3rd and 4th controllers if available

---

## Analog Stick Tuning

### Deadzone Configuration

N64-style racing benefits from tuned deadzones. The original N64 controller has an octagonal gate that restricts stick movement. 8BitDo controllers have circular gates, which can cause unintended diagonal inputs.

**Recommended approach:**
1. Start with default deadzones
2. If steering feels twitchy or drifts, increase the deadzone slightly
3. Use 8BitDo Ultimate Software to configure (see below)

### 8BitDo Ultimate Software

The [8BitDo Ultimate Software](https://support.8bitdo.com/ultimate/) allows:
- Button remapping
- Stick sensitivity and deadzone adjustment
- Trigger sensitivity
- Vibration intensity
- Profile creation and switching

**Important:** Configuration only works when the controller is connected via 2.4G dongle or USB cable (not Bluetooth).

To configure:
1. Install 8BitDo Ultimate Software on Windows
2. Connect the controller via its 2.4G dongle
3. Open the software and select the controller
4. Adjust stick deadzones under the "Stick" tab
5. Save the profile to the controller

---

## Controller-to-Player Mapping

SpaghettiKart assigns players based on controller connection order:

| Port | Dongle | Controller | Player |
|---|---|---|---|
| USB-A Port 1 | Dongle 1 | Controller 1 | Player 1 |
| USB-A Port 2 | Dongle 2 | Controller 2 | Player 2 |
| USB-A Port 3 | Dongle 3 | Controller 3 | Player 3 |
| USB-A Port 4 | Dongle 4 | Controller 4 | Player 4 |

If players are mapped incorrectly:
- Unplug all dongles
- Reconnect them in the desired order (Player 1 first, then 2, etc.)
- Restart SpaghettiKart

---

## Known Issues

### Split-screen multiplayer failure with multiple 8BitDo controllers on ROG Ally

Community reports indicate that some 8BitDo controller configurations may have issues with split-screen multiplayer on the ROG Ally. If this occurs:
- Test with only 2 controllers first
- Try different USB-A ports on the dock
- Test with the ROG Ally's built-in controls as Player 1 and external controllers for other players

### Input lag over wireless

If input feels delayed:
- Ensure the 2.4G dongle is plugged directly into the dock (not through a USB hub chain)
- Move the dongle closer to the controller
- Test with a USB cable to rule out wireless issues

### Controller not recognized

- Try a different USB-A port
- Restart the controller (hold power button for 5 seconds to turn off, then turn back on)
- Check if the dongle LED is blinking (searching) or solid (connected)

---

## Fallback: USB N64 Controller Adapters

If 8BitDo controllers are not viable for SpaghettiKart, USB N64 controller adapters are a backup option.

### Raphnet Adapter

The [Raphnet N64 to USB adapter](https://www.raphnet-tech.com/) supports:
- Original N64 controllers via USB
- Low latency
- No additional drivers needed on Windows

This is the most authentic input option but requires original N64 controllers.

### Other USB N64 Adapters

Generic USB N64 adapters are available on Amazon/eBay. Quality varies. Stick with adapters that have positive reviews for MK64 or SpaghettiKart specifically.

---

## Testing Checklist

- [ ] Single controller works in menus
- [ ] Single controller works in races (all buttons)
- [ ] Analog stick steering feels responsive (no drift)
- [ ] Second controller maps to Player 2
- [ ] No input crosstalk between controllers
- [ ] 4-player split-screen works (if 4 controllers available)
- [ ] Controllers work after SpaghettiKart restart
- [ ] Controller mapping survives dock disconnect/reconnect
