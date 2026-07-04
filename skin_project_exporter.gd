extends Node
## Editor/debug convenience: mirrors generated live skin files into the project asset tree.
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
		var source_path: String = str(SkinBank.call("get_skin_path", kind))
		var source_file: FileAccess = FileAccess.open(source_path, FileAccess.READ)
		if source_file == null:
			continue
		var source_text: String = source_file.get_as_text()
		source_file.close()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_path.get_base_dir()))
		var target_file: FileAccess = FileAccess.open(target_path, FileAccess.WRITE)
		if target_file != null:
			target_file.store_string(source_text)
			target_file.close()
