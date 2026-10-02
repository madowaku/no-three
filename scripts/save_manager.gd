class_name SaveManager
extends RefCounted

const SAVE_PATH: String = "user://progress.cfg"
var highest_unlocked_stage: int = 1
var completed_stages: Array[int] = []
var trace_enabled: bool = false
var save_path: String = SAVE_PATH

func load_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(save_path) != OK:
		return
	highest_unlocked_stage = clampi(int(config.get_value("progress", "highest_unlocked_stage", 1)), 1, 20)
	var completed: Variant = config.get_value("progress", "completed_stages", [])
	completed_stages.clear()
	if completed is Array:
		for stage_id: Variant in completed:
			if stage_id is int and stage_id >= 1 and stage_id <= 20 and not completed_stages.has(stage_id):
				completed_stages.append(stage_id)
	trace_enabled = bool(config.get_value("preferences", "trace_enabled", false))

func save_progress() -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("progress", "highest_unlocked_stage", highest_unlocked_stage)
	config.set_value("progress", "completed_stages", completed_stages)
	config.set_value("preferences", "trace_enabled", trace_enabled)
	var result: Error = config.save(save_path)
	if result != OK:
		push_error("Could not save progress: %s" % error_string(result))
	return result

func complete_stage(stage_id: int) -> void:
	if not completed_stages.has(stage_id):
		completed_stages.append(stage_id)
	highest_unlocked_stage = maxi(highest_unlocked_stage, mini(stage_id + 1, 20))
	save_progress()
