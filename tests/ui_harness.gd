extends "res://scripts/game_manager.gd"

@export var stage_to_show: int = 0:
	set(value):
		stage_to_show = value
		if is_node_ready() and value > 0:
			developer_unlock = true
			show_puzzle(value)

func _ready() -> void:
	save.save_path = "res://evidence/ui_progress.cfg"
	if FileAccess.file_exists(save.save_path):
		DirAccess.remove_absolute(save.save_path)
	super._ready()
	if stage_to_show > 0:
		developer_unlock = true
		show_puzzle(stage_to_show)
