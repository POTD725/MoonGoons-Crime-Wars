extends Node
## Runtime low-poly mesh catalog for the MoonGoons Command Deck.
## Models are original Godot primitive compositions designed from the project's
## officer roster language: navy armor, gold insignia, alien silhouettes, and
## clear faction hardware. They require no third-party model files.

const AUTHORITY: Color = Color("5dbcf0")
const AUTHORITY_TRIM: Color = Color("efc75e")
const CARTEL: Color = Color("e66aa9")
const CARTEL_TRIM: Color = Color("ffb86c")
const CHOIR: Color = Color("69dfb3")
const CHOIR_TRIM: Color = Color("b89cff")
const FANG: Color = Color("e88c5f")
const FANG_TRIM: Color = Color("ffd16a")

func build_model(kind: String, race_id: String) -> Node3D:
	var model: Node3D = Node3D.new()
	model.name = "Mesh_" + kind.capitalize()
	var palette: Dictionary = palette_for(race_id)
	var primary: Color = palette["primary"]
	var trim: Color = palette["trim"]
	if kind in ["drone", "signal_seed", "scrapwright"]:
		_build_drone(model, primary, trim)
	elif kind in ["shield", "enforcer", "brute"]:
		_build_heavy(model, primary, trim)
	elif kind in ["hero", "commander", "chief"]:
		_build_hero(model, primary, trim)
	elif kind in ["nexus", "syndicate_relay", "harmonic_core", "war_rig"]:
		_build_command_structure(model, primary, trim)
	elif kind in ["armory", "weapons_workshop", "cipher_foundry", "forge_yard"]:
		_build_armory_structure(model, primary, trim)
	elif kind in ["relay", "research_lab", "signal_spire", "war_drums"]:
		_build_relay_structure(model, primary, trim)
	elif kind in ["cells", "black_archive", "trophy_vault"]:
		_build_containment_structure(model, primary, trim)
	elif kind in ["medbay", "ghost_clinic", "memory_well", "recovery_pit"]:
		_build_medical_structure(model, primary, trim)
	elif kind in ["bay", "hangar", "smuggler_hangar", "echo_hatchery", "raider_hangar"]:
		_build_hangar_structure(model, primary, trim)
	elif kind in ["ore", "evidence", "intel_cache"]:
		_build_resource(model, kind, primary, trim)
	else:
		_build_infantry(model, primary, trim, kind)
	model.rotation_degrees = Vector3(-12.0, 24.0, 0.0)
	return model

func palette_for(race_id: String) -> Dictionary:
	match race_id:
		"lunar_cartel": return {"primary": CARTEL, "trim": CARTEL_TRIM}
		"null_choir": return {"primary": CHOIR, "trim": CHOIR_TRIM}
		"hollow_fang": return {"primary": FANG, "trim": FANG_TRIM}
		_: return {"primary": AUTHORITY, "trim": AUTHORITY_TRIM}

func _build_infantry(parent: Node3D, primary: Color, trim: Color, kind: String) -> void:
	var armor: StandardMaterial3D = _material(primary.darkened(0.46), 0.72, 0.28)
	var panel: StandardMaterial3D = _material(primary.darkened(0.18), 0.58, 0.34)
	var gold: StandardMaterial3D = _material(trim, 0.84, 0.25)
	var skin: StandardMaterial3D = _material(primary.lightened(0.18), 0.22, 0.62)
	_add_cylinder(parent, 0.12, 0.12, 0.48, Vector3(-0.15, 0.25, 0.0), armor)
	_add_cylinder(parent, 0.12, 0.12, 0.48, Vector3(0.15, 0.25, 0.0), armor)
	_add_box(parent, Vector3(0.52, 0.62, 0.30), Vector3(0.0, 0.77, 0.0), panel)
	_add_box(parent, Vector3(0.64, 0.16, 0.36), Vector3(0.0, 1.02, 0.0), armor)
	_add_sphere(parent, 0.24, Vector3(0.0, 1.30, 0.0), skin)
	_add_box(parent, Vector3(0.13, 0.10, 0.34), Vector3(0.0, 0.82, -0.18), gold)
	_add_box(parent, Vector3(0.14, 0.12, 0.45), Vector3(0.38, 0.82, 0.04), armor, Vector3(0.0, 0.0, -28.0))
	_add_box(parent, Vector3(0.11, 0.10, 0.70), Vector3(0.55, 0.85, -0.15), gold, Vector3(0.0, 0.0, -20.0))
	if kind in ["hacker", "scout", "detective"]:
		_add_cylinder(parent, 0.035, 0.035, 0.54, Vector3(-0.10, 1.63, 0.0), gold, Vector3(12.0, 0.0, 0.0))
		_add_sphere(parent, 0.06, Vector3(-0.16, 1.88, 0.0), gold)
	if kind in ["raider", "assault"]:
		_add_box(parent, Vector3(0.76, 0.08, 0.12), Vector3(0.0, 0.55, 0.17), gold)

func _build_heavy(parent: Node3D, primary: Color, trim: Color) -> void:
	var armor: StandardMaterial3D = _material(primary.darkened(0.36), 0.76, 0.24)
	var core: StandardMaterial3D = _material(primary, 0.64, 0.30)
	var gold: StandardMaterial3D = _material(trim, 0.86, 0.20)
	_add_cylinder(parent, 0.17, 0.17, 0.52, Vector3(-0.19, 0.27, 0.0), armor)
	_add_cylinder(parent, 0.17, 0.17, 0.52, Vector3(0.19, 0.27, 0.0), armor)
	_add_box(parent, Vector3(0.78, 0.80, 0.45), Vector3(0.0, 0.86, 0.0), core)
	_add_box(parent, Vector3(0.96, 0.22, 0.54), Vector3(0.0, 1.18, 0.0), armor)
	_add_sphere(parent, 0.29, Vector3(0.0, 1.53, 0.0), armor)
	_add_cylinder(parent, 0.50, 0.50, 0.11, Vector3(-0.56, 0.83, -0.06), gold, Vector3(90.0, 0.0, 0.0))
	_add_box(parent, Vector3(0.20, 0.14, 0.76), Vector3(0.55, 0.83, 0.04), gold, Vector3(0.0, 0.0, -18.0))
	_add_box(parent, Vector3(0.34, 0.11, 0.11), Vector3(0.0, 0.92, -0.29), gold)

func _build_drone(parent: Node3D, primary: Color, trim: Color) -> void:
	var hull: StandardMaterial3D = _material(primary.darkened(0.12), 0.66, 0.25)
	var glow: StandardMaterial3D = _emissive_material(trim, 1.05)
	_add_sphere(parent, 0.29, Vector3(0.0, 0.58, 0.0), hull)
	_add_box(parent, Vector3(0.36, 0.13, 0.36), Vector3(0.0, 0.58, 0.0), glow)
	for arm in [Vector3(-0.52, 0.58, 0.0), Vector3(0.52, 0.58, 0.0), Vector3(0.0, 0.58, -0.52), Vector3(0.0, 0.58, 0.52)]:
		_add_cylinder(parent, 0.04, 0.04, 0.52, arm * 0.5 + Vector3(0.0, 0.58, 0.0), hull, _arm_rotation(arm))
		_add_sphere(parent, 0.10, arm + Vector3(0.0, 0.58, 0.0), glow)
	_add_cylinder(parent, 0.06, 0.04, 0.28, Vector3(0.0, 0.18, 0.0), glow)

func _arm_rotation(direction: Vector3) -> Vector3:
	if absf(direction.x) > 0.1:
		return Vector3(0.0, 0.0, 90.0)
	return Vector3(90.0, 0.0, 0.0)

func _build_hero(parent: Node3D, primary: Color, trim: Color) -> void:
	_build_infantry(parent, primary, trim, "hero")
	var gold: StandardMaterial3D = _emissive_material(trim, 0.48)
	var halo: TorusMesh = TorusMesh.new()
	halo.inner_radius = 0.31
	halo.outer_radius = 0.35
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.mesh = halo
	ring.material_override = gold
	ring.position = Vector3(0.0, 1.57, 0.0)
	ring.rotation_degrees = Vector3(76.0, 0.0, 0.0)
	parent.add_child(ring)
	_add_box(parent, Vector3(0.12, 0.34, 0.52), Vector3(-0.46, 1.00, 0.05), gold, Vector3(0.0, 0.0, 18.0))

func _build_command_structure(parent: Node3D, primary: Color, trim: Color) -> void:
	var base: StandardMaterial3D = _material(primary.darkened(0.44), 0.74, 0.25)
	var shell: StandardMaterial3D = _material(primary.darkened(0.16), 0.62, 0.33)
	var glow: StandardMaterial3D = _emissive_material(trim, 0.68)
	_add_cylinder(parent, 1.16, 0.98, 0.30, Vector3(0.0, 0.15, 0.0), base)
	_add_box(parent, Vector3(1.48, 0.34, 1.18), Vector3(0.0, 0.44, 0.0), shell)
	_add_cylinder(parent, 0.34, 0.34, 1.18, Vector3(0.0, 1.03, 0.0), base)
	_add_sphere(parent, 0.36, Vector3(0.0, 1.64, 0.0), glow)
	for corner in [Vector3(-0.60, 0.74, -0.46), Vector3(0.60, 0.74, -0.46), Vector3(-0.60, 0.74, 0.46), Vector3(0.60, 0.74, 0.46)]:
		_add_cylinder(parent, 0.10, 0.10, 0.58, corner, glow)

func _build_armory_structure(parent: Node3D, primary: Color, trim: Color) -> void:
	var hull: StandardMaterial3D = _material(primary.darkened(0.40), 0.72, 0.27)
	var panel: StandardMaterial3D = _material(primary.darkened(0.12), 0.58, 0.34)
	var gold: StandardMaterial3D = _emissive_material(trim, 0.38)
	_add_box(parent, Vector3(1.62, 0.54, 1.06), Vector3(0.0, 0.36, 0.0), hull)
	_add_box(parent, Vector3(1.22, 0.22, 0.82), Vector3(0.0, 0.74, 0.0), panel)
	for x in [-0.46, 0.46]:
		_add_box(parent, Vector3(0.34, 0.20, 0.70), Vector3(x, 0.88, 0.0), gold)
	_add_cylinder(parent, 0.14, 0.14, 0.42, Vector3(0.0, 1.03, 0.0), gold)

func _build_relay_structure(parent: Node3D, primary: Color, trim: Color) -> void:
	var hull: StandardMaterial3D = _material(primary.darkened(0.35), 0.70, 0.25)
	var glow: StandardMaterial3D = _emissive_material(trim, 0.85)
	_add_cylinder(parent, 0.72, 0.62, 0.18, Vector3(0.0, 0.09, 0.0), hull)
	_add_cylinder(parent, 0.16, 0.12, 1.55, Vector3(0.0, 0.84, 0.0), hull)
	_add_sphere(parent, 0.24, Vector3(0.0, 1.72, 0.0), glow)
	for angle in [0.0, 120.0, 240.0]:
		var point: Vector3 = Vector3(0.43, 0.40, 0.0).rotated(Vector3.UP, deg_to_rad(angle))
		_add_cylinder(parent, 0.05, 0.05, 0.76, point + Vector3(0.0, 0.34, 0.0), glow, Vector3(20.0, angle, 0.0))

func _build_containment_structure(parent: Node3D, primary: Color, trim: Color) -> void:
	var hull: StandardMaterial3D = _material(primary.darkened(0.45), 0.70, 0.26)
	var bars: StandardMaterial3D = _material(trim, 0.86, 0.20)
	_add_box(parent, Vector3(1.64, 0.64, 1.18), Vector3(0.0, 0.34, 0.0), hull)
	for x in [-0.52, -0.26, 0.0, 0.26, 0.52]:
		_add_cylinder(parent, 0.035, 0.035, 0.76, Vector3(x, 0.89, -0.48), bars)
	_add_box(parent, Vector3(1.36, 0.12, 0.10), Vector3(0.0, 1.23, -0.48), bars)

func _build_medical_structure(parent: Node3D, primary: Color, trim: Color) -> void:
	var hull: StandardMaterial3D = _material(primary.darkened(0.25), 0.56, 0.35)
	var glow: StandardMaterial3D = _emissive_material(trim, 0.64)
	_add_box(parent, Vector3(1.48, 0.52, 1.06), Vector3(0.0, 0.28, 0.0), hull)
	_add_box(parent, Vector3(0.26, 0.86, 0.18), Vector3(0.0, 0.80, -0.55), glow)
	_add_box(parent, Vector3(0.86, 0.26, 0.18), Vector3(0.0, 0.80, -0.55), glow)
	_add_sphere(parent, 0.24, Vector3(-0.45, 0.86, 0.15), glow)

func _build_hangar_structure(parent: Node3D, primary: Color, trim: Color) -> void:
	var hull: StandardMaterial3D = _material(primary.darkened(0.42), 0.72, 0.26)
	var lights: StandardMaterial3D = _emissive_material(trim, 0.52)
	_add_box(parent, Vector3(1.86, 0.56, 1.32), Vector3(0.0, 0.30, 0.0), hull)
	_add_box(parent, Vector3(1.12, 0.62, 0.10), Vector3(0.0, 0.70, -0.66), lights)
	_add_box(parent, Vector3(0.94, 0.12, 0.78), Vector3(0.0, 0.60, -0.16), lights)
	for x in [-0.68, 0.68]:
		_add_cylinder(parent, 0.11, 0.11, 0.72, Vector3(x, 0.78, 0.32), hull)

func _build_resource(parent: Node3D, kind: String, primary: Color, trim: Color) -> void:
	var crystal: StandardMaterial3D = _emissive_material(trim if kind != "ore" else primary, 0.56)
	var rock: StandardMaterial3D = _material(primary.darkened(0.48), 0.48, 0.54)
	_add_cylinder(parent, 0.76, 0.56, 0.20, Vector3(0.0, 0.10, 0.0), rock)
	for offset in [Vector3(-0.30, 0.48, 0.02), Vector3(0.04, 0.64, -0.20), Vector3(0.34, 0.42, 0.18)]:
		_add_cylinder(parent, 0.14, 0.05, 0.76, offset, crystal)

func _add_box(parent: Node3D, size: Vector3, position: Vector3, material: Material, rotation_degrees: Vector3 = Vector3.ZERO) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	parent.add_child(instance)

func _add_sphere(parent: Node3D, radius: float, position: Vector3, material: Material) -> void:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)

func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position: Vector3, material: Material, rotation_degrees: Vector3 = Vector3.ZERO) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	parent.add_child(instance)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = _material(color, 0.50, 0.26)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
