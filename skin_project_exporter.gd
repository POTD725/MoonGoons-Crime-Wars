extends Node
## Editor/debug convenience: mirrors the generated live skin files into the project asset tree.
## Exported builds still use the safe user:// cache managed by SkinBank.

const PROJECT_ROOT: String = "res://assets/graphics/generated/"

func _ready() -> void:
	call_deferred("_mirror_skin_library")

func _mirror_skin_library() -> void:
	if SkinBank == null:
		return
	SkinBank.ensure_all_assets()
	for kind_value in SkinBank.CATALOG.keys():
		var kind: String = str(kind_value)
		var info: Dictionary = SkinBank.CATALOG[kind] as Dictionary
		var group_name: String = str(info.get("group", "misc"))
		var target_path: String = PROJECT_ROOT + group_name + "/" + kind + ".svg"
		if FileAccess.file_exists(target_path):
			continue
		var source: FileAccess = FileAccess.open(SkinBank.get_path(kind), FileAccess.READ)
		if source == null:
			continue
		var source_text: String = source.get_as_text()
		source.close()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_path.get_base_dir()))
		var target: FileAccess = FileAccess.open(target_path, FileAccess.WRITE)
		if target != null:
			target.store_string(source_text)
			target.close()
