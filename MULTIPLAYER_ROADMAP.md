# Multiplayer Roadmap

## Included in the playable demo

- LAN lobby and local callsigns
- Host/join flow for co-op recon sessions
- LAN chat and the persistent F8 in-game chat channel
- Custom Game roster configuration for 2v2, 4v4, 6v6, and 8v8
- Computer-controlled slots for local custom battles

## Deliberately not marked as finished

The custom roster can describe up to sixteen human or CPU slots, but only the local commander and CPU-controlled bases are part of the stable playable-demo target. A real multi-human RTS requires a separate host-authoritative implementation for:

1. Ready checks, teams, and faction selection in the lobby
2. Per-player spawn ownership and camera control
3. Replicated movement, build, train, attack, resource, and research commands
4. Deterministic combat or authoritative state synchronization
5. Fog-of-war visibility rules for each team
6. Match result agreement, reconnects, disconnects, and desync recovery

This boundary keeps the first Windows demo focused on a stable Story mission, CPU skirmish, and Free Roam instead of presenting an unfinished 8v8 network mode as complete.
