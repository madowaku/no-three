class_name StageLoader
extends RefCounted

static func load_stages() -> Array[Dictionary]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages.json"))
	var stages: Array[Dictionary] = []
	if parsed is not Array:
		push_error("Cannot read stage data")
		return stages
	for entry: Dictionary in parsed:
		stages.append(entry)
	return stages
