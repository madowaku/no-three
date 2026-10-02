extends SceneTree

var checked: int = 0
var failed: int = 0

func _initialize() -> void:
	_scan.call_deferred()

func _scan() -> void:
	visit("res://")
	print("PROJECT %s resources=%d failures=%d" % ["PASS" if failed == 0 else "FAIL", checked, failed])
	quit(0 if failed == 0 else 1)

func visit(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		failed += 1
		return
	for folder: String in directory.get_directories():
		if not folder.begins_with(".") and folder not in ["build", "evidence", "__pycache__"]:
			visit(path.path_join(folder))
	for file: String in directory.get_files():
		if file.get_extension() not in ["gd", "tscn", "tres"]:
			continue
		checked += 1
		var resource: Resource = load(path.path_join(file))
		if resource == null:
			failed += 1
		elif resource is PackedScene:
			var scene: Node = (resource as PackedScene).instantiate()
			if scene == null:
				failed += 1
			else:
				print("SCENE ", path.path_join(file), "\n", scene.get_tree_string_pretty())
				scene.free()
