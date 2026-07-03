# MoonGoons: Crime Wars — Campaign, Recon, Free Roam, and LAN Party

## Story campaign

Crime Wars is a four-faction conflict over the fractured lunar colonies. The player can approach the same crisis from the lawful MoonGoons Authority side or from the criminal and anomaly factions growing out of **Dark Side of the MoonGoons**.

### Campaign arcs

1. **The Broken Docks**: Breakwater Dockyard is being used to move prisoners through fake relief cargo.
2. **Ghostlight Protocol**: survivor records reveal that the official evacuation never happened the way the Bureau claims.
3. **The Null Choir Sings**: a rogue signal broadcasts memories from the first lunar fracture.
4. **Fang at the Gate**: Hollow Fang converts prison transports into boarding fortresses and races for the buried moon-city.

The first library contains 12 missions, from `CW-001 Operation Breakwater` to `CW-012 The Second Siren`. Each has Authority and Dark Side goals, rewards, and a decision that can affect later paths.

## Recon gameplay

Recon is the campaign's clue engine.

- Recon sites unlock alternate infiltration routes, new objectives, mission weaknesses, equipment, ending paths, and alliances.
- Every recon site has a task, a reveal, and a risk.
- Example: **Chapel Vent Array** maps coolant lines under the Null machine. Completing it weakens boss shields in `CW-008 The Machine Underneath`.

## Free Roam: The Fracture Belt

Open the **Mode Hub** with `F2`, then select **Free Roam**.

Controls:

- `W A S D`: move the recon vessel
- Hold `E` near an amber beacon: scan a recon site
- `1` / `2` / `3` / `4`: switch the vessel's faction visual style
- `Enter`: return to RTS Operations
- `F2`: return to the Mode Hub

The free-roam map contains eight story recon beacons, hostile patrol markers, Intel rewards, Credits, and campaign clues.

## LAN Party: shared co-op recon

Open the **Mode Hub** with `F2`, then select **LAN Party**.

### Host

1. Enter a callsign.
2. Keep the default port `24571`, unless your group agrees on another port.
3. Press **HOST PARTY**.
4. Share the listed local IPv4 address with players on the same Wi-Fi/router.
5. When everyone appears in the roster, press **HOST: START CO-OP RECON**.

### Join

1. Enter a callsign.
2. Type the host's local IPv4 address, for example `192.168.4.25`.
3. Use the same port as the host.
4. Press **JOIN PARTY**.

### Co-op controls

- `W A S D`: move your local recon ship
- `E`: capture a nearby recon beacon
- `Esc`: return to the LAN lobby
- `F2`: Mode Hub

The host validates and shares beacon captures. Player markers and movement are synchronized across the local network, and the lobby provides roster and chat.

### Current LAN scope

The LAN feature is a playable co-op reconnaissance party. It is **not yet a fully synchronized competitive RTS battle** with network authority for every troop, bullet, building, and AI order. That next phase needs deterministic or host-authoritative RTS simulation, latency handling, desync checks, reconnect support, and match results.

## Four RTS factions

| Faction | Style | Construction | Economy | Hero |
|---|---|---|---|---|
| MoonGoons Authority | shielded police precinct | Builder Drones deploy reliable modules | Supplies per finished building | Chief Nova |
| Lunar Cartel | neon hidden depot | Contraband Riggers build fast, fragile modules | Credits and Intel per finished building | Vexa Null |
| Null Choir | living signal network | Signal Seeds grow slow data-structures | Intel per finished building | Nyx Relay |
| Hollow Fang Clan | welded scrap war-camp | Scrapwrights raise durable structures fast | Supplies and Credits per finished building | Nash Vanta |

At launch, RTS mode presents a faction selection screen. Press `F1` in RTS mode to reopen it for development testing.
