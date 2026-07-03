extends Node
## Story, mission, and reconnaissance library for MoonGoons: Crime Wars.
## All entries are original MoonGoons setting material.

const CAMPAIGN_ARCS := [
	{
		"id":"arc_01_breakwater",
		"title":"THE BROKEN DOCKS",
		"chapter":"Chapter I",
		"summary":"Breakwater Dockyard is caught between a MoonGoons relief operation and a Lunar Cartel extraction run. Somebody is moving prisoners through a condemned freight spine.",
		"missions":["CW-001","CW-002","CW-003"],
		"recon_unlocks":["RX-01","RX-02"]
	},
	{
		"id":"arc_02_ghostlight",
		"title":"GHOSTLIGHT PROTOCOL",
		"chapter":"Chapter II",
		"summary":"The Ghostlight Collective asks for help locating civilians missing from the evacuation roster. The Bureau says there was no evacuation. The evidence says otherwise.",
		"missions":["CW-004","CW-005","CW-006"],
		"recon_unlocks":["RX-03","RX-04"]
	},
	{
		"id":"arc_03_null",
		"title":"THE NULL CHOIR SINGS",
		"chapter":"Chapter III",
		"summary":"A data relay begins broadcasting memories from the first lunar fracture. The Null Choir calls it a birth certificate. Everyone else calls it a weapon.",
		"missions":["CW-007","CW-008","CW-009"],
		"recon_unlocks":["RX-05","RX-06"]
	},
	{
		"id":"arc_04_fang",
		"title":"FANG AT THE GATE",
		"chapter":"Chapter IV",
		"summary":"Hollow Fang Clan converts derelict prison transports into boarding fortresses. Their target is the only navigation map that can reach the buried moon-city beneath Selene.",
		"missions":["CW-010","CW-011","CW-012"],
		"recon_unlocks":["RX-07","RX-08"]
	}
]

const MISSIONS := [
	{
		"id":"CW-001","title":"Operation Breakwater","type":"RTS Assault","location":"Breakwater Dockyard","brief":"Establish a forward base, protect trapped civilians, and destroy the Syndicate relay coordinating the raid.","authority":"Secure evidence and extract survivors.","dark_side":"Steal the relay key before the Authority erases the ledger.","reward":"Armory plans, 300 Credits, Breakwater access.","choice":"Arrest the relay engineer or trade them to the Ghostlight Collective."
	},
	{
		"id":"CW-002","title":"The Quiet Cargo","type":"Recon / Infiltration","location":"Dock 7 Freight Spine","brief":"A cargo manifest lists medical supplies that never reached the colony. Scan containers, follow heat signatures, and identify the false customs seal.","authority":"Recover medicine without damaging sealed cargo.","dark_side":"Extract the shipment and pin the theft on the Bureau.","reward":"Evidence Cache, Cargo Scanner upgrade.","choice":"Expose the Cartel route or sell it to fund the precinct."
	},
	{
		"id":"CW-003","title":"Blackout at Cinder Row","type":"Holdout","location":"Cinder Row Habitat","brief":"Vexa Null cuts lights across a civilian block while raiders search for a witness. Defend power relays until evacuation ships arrive.","authority":"Keep three power relays online.","dark_side":"Capture the witness before the first transport leaves.","reward":"Field Medbay unlock, civilian reputation.","choice":"Save the witness or save the grid."
	},
	{
		"id":"CW-004","title":"Names Missing","type":"Investigation","location":"Ghostlight Safehouse","brief":"Search abandoned housing records, interview survivors, and follow a forged evacuation order to a hidden tram station.","authority":"Prove the Bureau altered the records.","dark_side":"Use the names to recruit a desperate crew.","reward":"Ghostlight contacts, Safehouse map.","choice":"Publish the evidence or protect the survivors' identities."
	},
	{
		"id":"CW-005","title":"The Prison Moon Run","type":"Extraction","location":"Kestrel Detention Moon","brief":"A prison transfer is carrying political detainees and a rogue architect. Infiltrate the convoy, disable its escort grid, and decide who gets off the shuttle.","authority":"Extract detainees and preserve chain-of-custody.","dark_side":"Break everyone out and claim the architect.","reward":"Containment tech, new crew option.","choice":"Rescue the architect or recover the prison blueprints."
	},
	{
		"id":"CW-006","title":"Velvet Ledger","type":"Social Recon","location":"Velvet Nebula","brief":"A gala is hiding a debt auction for lunar districts. Use a face, a forged invitation, or a stealth team to find the bidder behind the blackout funds.","authority":"Identify the bidder without starting a panic.","dark_side":"Win the auction and gain the district's debt.","reward":"Influence, Forgery Lab concept.","choice":"Burn the ledger or weaponize it."
	},
	{
		"id":"CW-007","title":"Memory of a Tuesday","type":"Anomaly Recon","location":"Null Choir Relay","brief":"Every camera at the relay shows the same ordinary Tuesday, but different people are alive in each version. Map the signal without losing your squad to the loop.","authority":"Quarantine the loop and retrieve one living witness.","dark_side":"Copy the memory pattern for blackmail.","reward":"Signal Spire, long-range recon.","choice":"Free the witness or preserve the loop."
	},
	{
		"id":"CW-008","title":"The Machine Underneath","type":"Siege / Puzzle","location":"Null Chapel","brief":"A buried machine awakens under the chapel and begins turning station systems against every faction. Claim its root key before it locks the moon down.","authority":"Stop the machine and protect the settlement.","dark_side":"Install a private backdoor before shutting it down.","reward":"Null Archive, heroic equipment.","choice":"Destroy the root key or divide it among the factions."
	},
	{
		"id":"CW-009","title":"Choir of Static","type":"RTS Defense","location":"Harmonic Scar","brief":"Null Choir echoes manifest as autonomous defense forms. Hold the scar while recon drones translate the pulse into coordinates.","authority":"Defend the translators.","dark_side":"Jam the drones and sell the coordinates.","reward":"Deep-space coordinate shard.","choice":"Follow the signal immediately or fortify first."
	},
	{
		"id":"CW-010","title":"Hollow Fang Boarders","type":"Boarding Action","location":"Graveyard Belt","brief":"Fang raiders seize a wreck graveyard and turn civilian tugs into gun platforms. Board the flagship or dismantle its supply train.","authority":"Disable the flagship with minimal casualties.","dark_side":"Take the flagship and earn Fang respect.","reward":"Raider Hangar, boarding gear.","choice":"Capture the captain or take the fleet code."
	},
	{
		"id":"CW-011","title":"Trophy Moon","type":"Free-Roam Hunt","location":"Hollow Fang Reach","brief":"Scattered war trophies each point to an older lunar map. Explore four hostile zones, complete recon tasks in any order, and decide who receives the assembled route.","authority":"Recover artifacts for public archives.","dark_side":"Sell trophies to rival clans.","reward":"Open-sector travel and hero upgrades.","choice":"Unite the clans or fracture them."
	},
	{
		"id":"CW-012","title":"The Second Siren","type":"Finale","location":"Selene Under-City","brief":"The original fracture alarm begins again. Every faction arrives with a different answer: rescue, profit, ascension, or conquest. Build, scout, and survive long enough to choose the moon's future.","authority":"Evacuate districts and seal the fracture.","dark_side":"Control the alarm network and end Bureau rule.","reward":"Campaign ending, faction epilogue, New Game Plus sectors.","choice":"The ending changes with your alliances and recon evidence."
	}
]

const RECON_SITES := [
	{"id":"RX-01","name":"Collapsed Customs Mast","sector":"Breakwater","task":"Scan three concealed cargo transponders.","reveal":"Unlocks a smuggler tunnel route in CW-002.","risk":"A Cartel decoy can summon raiders."},
	{"id":"RX-02","name":"Cinder Row Roofline","sector":"Breakwater","task":"Mark evacuation paths and sniper nests.","reveal":"Adds civilian rescue objectives to CW-003.","risk":"Power storms reduce sensor range."},
	{"id":"RX-03","name":"Ghostlight Tram Platform","sector":"Forgotten Moon","task":"Follow an evacuation wristband signal.","reveal":"Identifies the forged order source for CW-004.","risk":"False survivor recordings lead into a trap."},
	{"id":"RX-04","name":"Kestrel Debris Halo","sector":"Kestrel Moon","task":"Survey prison convoy debris fields.","reveal":"Finds an alternate insertion route for CW-005.","risk":"Autonomous prison turrets reactivate."},
	{"id":"RX-05","name":"Mirror Antenna","sector":"Null Choir Relay","task":"Tune a scanner to the repeating memory pulse.","reveal":"Shows the true objective marker in CW-007.","risk":"Squads may receive false navigation pings."},
	{"id":"RX-06","name":"Chapel Vent Array","sector":"Null Chapel","task":"Map coolant lines beneath the machine.","reveal":"Weakens the boss shields in CW-008.","risk":"The system can corrupt one active relay."},
	{"id":"RX-07","name":"Fang Wreck Shrine","sector":"Graveyard Belt","task":"Identify which ship trophies are functional weapons.","reveal":"Unlocks a boarding skiff for CW-010.","risk":"Fang scouts challenge trespassers."},
	{"id":"RX-08","name":"Siren Observatory","sector":"Selene Under-City","task":"Triangulate fracture alarm echoes.","reveal":"Adds a New Game Plus ending path in CW-012.","risk":"The signal paints your base on every faction's map."}
]

func get_mission(mission_id: String) -> Dictionary:
	for mission in MISSIONS:
		if mission["id"] == mission_id:
			return mission
	return {}

func get_recon(site_id: String) -> Dictionary:
	for site in RECON_SITES:
		if site["id"] == site_id:
			return site
	return {}
