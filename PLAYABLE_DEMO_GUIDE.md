# MoonGoons: Crime Wars — Playable Demo Guide

## What the first playable demo contains

- Launch screen with Story, Custom Game, Free Roam, and Settings entry points
- `CW-001: Operation Breakwater` as the first guided RTS mission
- Faction choice, map selection, difficulty selection, resource gathering, building, troop training, combat, victory, and defeat flow
- Escalating campaign CPU response
- Custom skirmish setup with maps, CPU slots, scenarios, and difficulties
- Free Roam alliance companion loop
- Command Deck, tactical map, chat, officer roster, imported MoonGoons art, generated unit/object previews, and battlefield silhouettes
- Persistent settings and CW-001 completion stored in `user://moongoons_profile.cfg`

## First-run path

1. Launch the project.
2. On the launch screen, choose **Start Operation Breakwater**.
3. Pick a faction from the faction selector.
4. Select a Builder Drone.
5. Build a Tactical Armory with `1` or the Command Deck button.
6. Gather Ore and train more deputies with the Nexus selected.
7. Destroy the Syndicate Relay.
8. Use the mission result card to retry or open the Mode Hub.

## Test checklist

### Launch and navigation

- [ ] Launch screen appears.
- [ ] Story launch exposes faction selection.
- [ ] Custom Game opens from launch screen and Mode Hub.
- [ ] Free Roam opens from launch screen and Mode Hub.
- [ ] `F2` Mode Hub, `F4` difficulty, `F5` campaign board, `F7` roster, `F8` chat, `F9` developer console, `F10` settings, and `P` pause all open and close correctly.

### CW-001 core loop

- [ ] Builder Drone can harvest Ore and Evidence.
- [ ] Build placement blocks invalid locations.
- [ ] Armory construction completes.
- [ ] Nexus trains Builder Drones and Deputies.
- [ ] Armory trains Shield Deputies.
- [ ] Units move, attack, and receive combat feedback.
- [ ] Enemy reinforcement groups deploy.
- [ ] Destroying the Syndicate Relay produces a mission-complete screen.
- [ ] Losing the Command Nexus produces a failure screen.
- [ ] Finishing CW-001 records campaign progress after a restart.

### Visual and UI check

- [ ] Command Deck resource telemetry updates.
- [ ] Imported MoonGoons structure art appears in the selected-building dossier.
- [ ] Generated low-poly model preview appears for a selected troop.
- [ ] Battlefield silhouettes appear for drones, troops, and structures.
- [ ] Officer Roster opens with `F7`.

## Windows export

Install Godot 4.7 export templates, then either:

- Double-click `tools/export_windows.bat` from Windows, or
- In Godot, open **Project → Export → Windows Desktop → Export Project**.

The expected output is `builds/windows/MoonGoonsCrimeWars.exe`.

## Current multiplayer boundary

The Custom Game War Room can configure 2v2, 4v4, 6v6, and 8v8 rosters. CPU slots are used in local matches. The full per-human synchronized LAN/online RTS layer is not part of this demo release yet; it requires host-authoritative command replication, lobby readiness, desync recovery, reconnect behavior, and shared match results.
