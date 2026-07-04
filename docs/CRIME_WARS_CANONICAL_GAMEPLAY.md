# MoonGoons: Crime Wars — Canonical Gameplay Contract

This document is the implementation target for the playable RTS build.

## Core match loop

1. Start with a Command Nexus, a small Lunar Peacekeeper force, and nearby deposits.
2. Collect Credits, Intel, Lunar Alloy, and Evidence with Builder Drones.
3. Construct a precinct: Tactical Armory, Drone Bay, Field Medbay, Holding Cells, Evidence Vault, Communications Relays, defenses, Air Support Pad, and Orbital Watchtower.
4. Expand Command Capacity with Command Nexus upgrades, Communications Relays, Leadership Network research, and Watchtowers.
5. Capture districts for timed income and battlefield control.
6. Win objective-driven operations through combat, evidence recovery, defense, arrest/investigation systems, extraction, or network destruction.

## Resources

- **Credits:** basic construction and recruitment.
- **Supplies:** sustainment and mission-score resource.
- **Intel:** tactical support and investigation currency.
- **Lunar Alloy:** advanced buildings, armored units, aircraft, and Nexus upgrades.
- **Evidence:** recovered from Evidence Caches and districts; used for leadership and special-unit unlocks.

## Command Capacity

Every friendly unit uses Command Capacity. Capacity comes from:

- Command Nexus base capacity and upgrades
- Communications Relays
- Orbital Watchtowers
- Evidence Vault support
- Leadership Network research

Production queues reserve capacity before units deploy, preventing hidden over-cap queues.

## Major forces

- **Lunar Peacekeepers:** balanced defense, repairs, healing, arrests, investigations, and orbital support.
- **The Syndicate:** raids, sabotage, hacking, hidden operations, black-market logistics, and ambushes.
- **The Nullborn:** corrupted territory, unstable energy, infected infrastructure, environmental pressure, and late-game mutations.

## Campaign slice currently implemented

- **CW-001 Operation Breakwater:** build a precinct and destroy the hostile relay.
- **CW-002 The Quiet Cargo:** collect and return 80 Intel from Evidence Caches.
- **CW-003 Blackout at Cinder Row:** build three Communications Relays and hold for 120 seconds after hostile operations activate.

Mission completion writes to the player profile and opens a debrief with a next-operation button.

## Game modes

- **Campaign:** objective-driven story operations and unlock progression.
- **Skirmish:** configurable CPU matches through the custom-game path.
- **Multiplayer:** LAN lobby, co-op, and versus foundations. Network authority and public matchmaking remain a later production milestone.
