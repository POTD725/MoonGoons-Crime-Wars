extends Node
## Data-driven race loadouts for Crime Wars.

func buildings_for(player_race: String, rival_race: String) -> Dictionary:
	var player := building_set(player_race)
	var rival := building_set(rival_race)
	player["syndicate_relay"] = rival["nexus"].duplicate(true)
	player["syndicate_relay"]["name"] = rival["nexus"]["name"]
	player["syndicate_relay"]["hp"] = int(rival["nexus"]["hp"]) + 420
	player["syndicate_relay"]["size"] = Vector2(138, 100)
	return player

func units_for(player_race: String, rival_race: String) -> Dictionary:
	var player := unit_set(player_race)
	var rival := unit_set(rival_race)
	player["raider"] = rival["deputy"].duplicate(true)
	player["hacker"] = rival["shield"].duplicate(true)
	return player

func building_set(race_id: String) -> Dictionary:
	match race_id:
		"authority":
			return {
				"nexus": b("Ops Center", 0, Vector2(116,86), 1280, 0.0, "#5b82f2"),
				"armory": b("Armory", 150, Vector2(94,72), 900, 7.0, "#c08aff"),
				"relay": b("Research Lab", 80, Vector2(52,52), 500, 4.0, "#65ddff"),
				"medbay": b("Medbay", 120, Vector2(78,62), 690, 6.0, "#6de4b0"),
				"bay": b("Hangar", 150, Vector2(82,62), 720, 7.0, "#7eaaff"),
				"cells": b("Holding Cells", 170, Vector2(100,76), 980, 8.0, "#f6c26f")
			}
		"lunar_cartel":
			return {
				"nexus": b("Syndicate Command Nest", 0, Vector2(108,80), 980, 0.0, "#ff66b5"),
				"armory": b("Weapons Workshop", 135, Vector2(90,68), 650, 2.5, "#de79ff"),
				"relay": b("Hacker Den", 55, Vector2(50,50), 360, 1.5, "#6ff0d6"),
				"medbay": b("Ghost Clinic", 95, Vector2(74,58), 480, 2.0, "#78b8ff"),
				"bay": b("Smuggler Hangar", 115, Vector2(80,60), 550, 2.5, "#64e4ff"),
				"cells": b("Black Market Vault", 145, Vector2(96,72), 690, 3.0, "#d767ff")
			}
		"null_choir":
			return {
				"nexus": b("Harmonic Core", 0, Vector2(112,84), 1120, 0.0, "#63f0c1"),
				"armory": b("Cipher Foundry", 135, Vector2(90,70), 770, 9.0, "#53d5d0"),
				"relay": b("Signal Spire", 70, Vector2(54,54), 460, 7.0, "#a5ffcf"),
				"medbay": b("Memory Well", 110, Vector2(78,62), 610, 8.0, "#76f3e0"),
				"bay": b("Echo Hatchery", 130, Vector2(84,64), 650, 9.0, "#8ae6ff"),
				"cells": b("Black Archive", 165, Vector2(98,76), 800, 10.0, "#80ffc0")
			}
		_:
			return {
				"nexus": b("War-Rig", 0, Vector2(120,88), 1460, 0.0, "#ff8e52"),
				"armory": b("Forge Yard", 150, Vector2(96,74), 1120, 4.0, "#ff6e57"),
				"relay": b("War Drums", 70, Vector2(54,54), 570, 3.0, "#ffc45b"),
				"medbay": b("Recovery Pit", 100, Vector2(80,64), 760, 4.0, "#ff8f7e"),
				"bay": b("Raider Hangar", 135, Vector2(86,66), 850, 4.5, "#ffb85b"),
				"cells": b("Trophy Vault", 165, Vector2(102,78), 1080, 5.0, "#f28b57")
			}

func unit_set(race_id: String) -> Dictionary:
	match race_id:
		"authority":
			return {
				"drone": u("Builder Drone", 100, 145.0, 0.0, 0, 0.0, 15.0, "#91edff", 65, 4.0),
				"deputy": u("Deputy Karr", 165, 124.0, 158.0, 14, 0.64, 18.0, "#a0baff", 85, 5.0),
				"shield": u("Enforcer Vox", 300, 92.0, 108.0, 22, 0.82, 23.0, "#ddb0ff", 145, 8.0),
				"hero": u("Chief Nova", 520, 116.0, 175.0, 33, 0.60, 27.0, "#e7f0ff", 0, 0.0)
			}
		"lunar_cartel":
			return {
				"drone": u("Contraband Rigger", 75, 170.0, 0.0, 0, 0.0, 14.0, "#ff9ed2", 55, 2.5),
				"deputy": u("Mox Vell Runner", 130, 150.0, 150.0, 17, 0.55, 17.0, "#ff72b7", 75, 3.5),
				"shield": u("Brunt K-9 Breaker", 245, 108.0, 96.0, 29, 0.72, 24.0, "#ffb05c", 130, 5.5),
				"hero": u("Vexa Null", 360, 132.0, 215.0, 27, 0.46, 23.0, "#b281ff", 0, 0.0)
			}
		"null_choir":
			return {
				"drone": u("Signal Seed", 70, 126.0, 0.0, 0, 0.0, 14.0, "#87ffd0", 60, 5.0),
				"deputy": u("Choir Echo", 120, 118.0, 180.0, 15, 0.50, 16.0, "#63f0c1", 80, 5.0),
				"shield": u("Null Warden", 230, 104.0, 145.0, 25, 0.70, 22.0, "#89e6ff", 140, 7.0),
				"hero": u("Nyx Relay", 390, 122.0, 240.0, 31, 0.42, 22.0, "#d0ffea", 0, 0.0)
			}
		_:
			return {
				"drone": u("Scrapwright", 120, 116.0, 0.0, 0, 0.0, 17.0, "#ffae63", 70, 3.5),
				"deputy": u("Fang Skirmisher", 190, 118.0, 116.0, 22, 0.68, 20.0, "#ff815d", 90, 5.0),
				"shield": u("Boarder Brute", 350, 86.0, 84.0, 37, 0.90, 27.0, "#ffbd64", 155, 7.0),
				"hero": u("Nash Vanta", 500, 112.0, 160.0, 39, 0.66, 26.0, "#ffe29d", 0, 0.0)
			}

func b(name: String, cost: int, size: Vector2, hp: int, time: float, color: String) -> Dictionary:
	return {"name":name, "cost":cost, "size":size, "hp":hp, "time":time, "color":Color(color)}

func u(name: String, hp: int, speed: float, attack_range: float, damage: int, cooldown: float, radius: float, color: String, cost: int, time: float) -> Dictionary:
	return {"name":name, "hp":hp, "speed":speed, "range":attack_range, "damage":damage, "cool":cooldown, "r":radius, "color":Color(color), "cost":cost, "time":time}
