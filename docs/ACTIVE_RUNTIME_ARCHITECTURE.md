# MoonGoons: Crime Wars — Active Runtime Architecture

## Canonical playable path

`main.tscn` uses `resource_density_layer.gd` as the active scene script.

The current scene lineage remains transitional, but new cross-cutting systems must be added as autoload services instead of adding more scene inheritance layers.

## Ownership boundaries

- `moonfront_rts.gd`: legacy original RTS simulation base. Do not add new features here.
- `frontier_map_layer.gd`: battlefield geometry, collision, terrain, spawns, and authored map profiles.
- `campaign_map_router.gd`: chooses campaign battlefield identity while preserving Custom Game map selection.
- `crime_wars_gameplay_core.gd`: Credits, Intel, Lunar Alloy, Evidence, Command Capacity, districts, and precinct systems.
- `resource_density_layer.gd`: balanced starter, contested, and high-risk map resource expansion.
- `CampaignMissionDirector` autoload: campaign-only chapter dressing and guarded resource objectives.
- `RuntimeGuard` autoload: hidden-focus recovery and effect/projectile safety caps.
- `CustomMatchRuntime` / `CustomMatchAI`: Custom Game objective and CPU systems.

## Legacy paths

`main.gd` and `main_safe.gd` are legacy, inactive entrypoints. They remain in the repository for reference during migration but must not be used as parents for new gameplay work.

## Three implemented chapters

- **CW-001 Operation Breakwater**: Nexus Prime, destroy the Syndicate Relay.
- **CW-002 The Quiet Cargo**: Underhive Sector, guarded Evidence Cache recovery.
- **CW-003 Blackout at Cinder Row**: Black Crater, build three Communications Relays and protect them for 120 seconds after they are operational.

## Next migration rule

When a system is independent of the scene's core tick, it belongs in a service/autoload or dedicated component, not a new parent script.
