# MoonGoons: Crime Wars — Art Pipeline

## Vertical-slice visual direction

The playable demo uses an original **lunar command-and-crime** visual language: deep navy Authority infrastructure, neon Cartel hardware, ghostly signal technology, and heavy salvage war machines. The first polished battlefield is **Operation Breakwater**, a damaged lunar customs dock where Authority blue and Cartel pink collide.

The current vertical slice contains in-engine illustrated faction cards, procedural troop silhouettes, animated buildings, dockyard props, construction scaffolds, projectiles, impacts, and synthesized tactical sounds. These are designed as stable placeholders for higher-fidelity original art, not as borrowed content from any other game.

## Asset layout

```text
assets/
  units/
    authority/
    lunar_cartel/
    null_choir/
    hollow_fang/
  buildings/
    authority/
    lunar_cartel/
    null_choir/
    hollow_fang/
  terrain/
    breakwater/
    craters/
    debris/
    props/
  effects/
    weapons/
    explosions/
    construction/
    shields/
  ui/
    icons/
    portraits/
    faction_badges/
  audio/
    sfx/
    voices/
    music/
```

## First production pack

### Authority
- Builder Drone
- Patrol Deputy
- Shield Deputy
- Chief Nova
- Command Nexus
- Tactical Armory
- Power Relay
- Field Medbay
- Drone Bay
- Containment Block

### Lunar Cartel
- Raider
- Hacker
- Vexa Null
- Syndicate Relay
- Contraband cargo skiff
- Cartel command nest

### Breakwater props
- Lunar dock ground tiles
- Rail line and crane
- Cargo containers
- Evidence cache
- Security barriers
- Wrecked shuttle
- Flood lamps
- Smuggler signage

## Integration rule

Every production asset must be connected to one data identifier used by the RTS core, such as `drone`, `deputy`, `shield`, `hero`, `raider`, `hacker`, `nexus`, `armory`, or `syndicate_relay`. Keep the asset identifier identical to the game identifier so a visual never becomes an orphaned file.

## Animation targets

Each unit should eventually include idle, move, attack, hit, death, and selection states. Each building should include blueprint, construction, online idle, damaged, and destroyed states. The current in-engine presentation demonstrates those state changes in code so future sprite or 3D asset swaps have a clear target.
