# MoonGoons Command Deck

The in-game player interface is an original MoonGoons RTS command console: lunar-alloy panels, Authority cyan telemetry, evidence-gold map details, heavy readable buttons, and faction-sensitive dossier colors.

It uses classic RTS interface principles such as persistent resource telemetry, selection information, production controls, alerts, and a tactical minimap. It does not reproduce another game's exact UI artwork, layout, icons, or branding.

## Live interface panels

### Top telemetry strip

- Operation map and global difficulty
- Credits, Supplies, and Intel
- Current mission alert feed
- MoonGoons command crest

### Active dossier

- Selected unit, squad, or structure
- Integrity bar and health percentage
- Faction identity, current order, damage, and range
- Procedural tactical portrait that changes for drones, squads, command structures, and heroes

### Tactical orders

The buttons are clickable and mirror keyboard shortcuts:

| Action | Key | Requirement |
|---|---:|---|
| Tactical Armory | `1` | Builder Drone selected |
| Power Relay | `2` | Builder Drone selected |
| Field Medbay | `3` | Builder Drone selected |
| Drone Bay | `4` | Builder Drone selected |
| Containment Block | `5` | Builder Drone selected |
| Train Deputy | `Q` | Command Nexus selected |
| Train Builder Drone | `E` | Command Nexus selected |
| Train Shield Deputy | `R` | Tactical Armory selected |
| Focus selection | `F` | A unit or structure selected |
| Cancel build order | `Esc` | Any active placement order |
| Battlefield archive | `F3` | Any RTS match |
| Difficulty console | `F4` | Any game mode |

Buttons dim when their selection requirement is not met.

### Tactical map

- Cyan markers: friendly units and structures
- Red markers: enemy units and structures
- Cyan / gold pips: Ore and Evidence deposits
- White frame: current camera viewport
- Left-click the tactical map to move the camera to that sector

## Interface hotkeys

- `F1`: faction selection in normal RTS Operations
- `F2`: Mode Hub
- `F3`: PvP Battlefield Archive
- `F4`: global Difficulty Console
- `F6`: Free Roam Alliance Console
- `F8`: Chat
- `F9`: Developer Console

The Command Deck intentionally hides behind full-screen selection, campaign dialogue, map-selection, difficulty, and alliance menus so those screens remain readable.
