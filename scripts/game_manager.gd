extends Control

const TITLE: PackedScene = preload("res://scenes/title_screen.tscn")
const STAGE_SELECT: PackedScene = preload("res://scenes/stage_select.tscn")
const PUZZLE: PackedScene = preload("res://scenes/puzzle_screen.tscn")
const PALETTE: VisualPalette = preload("res://themes/palette.tres")
var stages: Array[Dictionary] = []
var save: SaveManager = SaveManager.new()
var current_screen: Control
var developer_unlock: bool = false
@onready var host: Control = %ScreenHost

func _ready() -> void:
	stages = StageLoader.load_stages()
	developer_unlock = OS.is_debug_build() and OS.get_cmdline_user_args().has("--unlock-all")
	save.load_progress()
	resized.connect(_layout)
	_layout()
	show_title()

func _layout() -> void:
	var factor: float = minf(1.0, minf(size.x / 720.0, size.y / 1280.0))
	if factor <= 0.0:
		return
	host.scale = Vector2.ONE * factor
	host.size = Vector2(720.0, size.y / factor)
	host.position = Vector2((size.x - 720.0 * factor) * 0.5, 0.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PALETTE.background)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_screen != null and current_screen.has_method("handle_cell"):
			show_stages()
		else:
			show_title()
		get_viewport().set_input_as_handled()

func _replace(scene: PackedScene) -> Control:
	if current_screen != null:
		host.remove_child(current_screen)
		current_screen.queue_free()
	current_screen = scene.instantiate() as Control
	if current_screen == null:
		push_error("Invalid screen scene")
		return null
	host.add_child(current_screen)
	current_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return current_screen

func show_title() -> void:
	var screen: Control = _replace(TITLE)
	screen.set_progress(save.highest_unlocked_stage, save.completed_stages.size())
	screen.play_requested.connect(show_stages)
	screen.stages_requested.connect(show_stages)

func show_stages() -> void:
	var screen: Control = _replace(STAGE_SELECT)
	screen.configure(stages, save, developer_unlock)
	screen.stage_requested.connect(show_puzzle)
	screen.back_requested.connect(show_title)

func show_puzzle(stage_id: int) -> void:
	if stage_id < 1 or stage_id > stages.size():
		return
	if not developer_unlock and stage_id > save.highest_unlocked_stage:
		return
	var screen: Control = _replace(PUZZLE)
	screen.configure(stages[stage_id - 1], save.trace_enabled)
	screen.stage_completed.connect(save.complete_stage)
	screen.next_requested.connect(show_puzzle)
	screen.stages_requested.connect(show_stages)
	screen.trace_changed.connect(_save_trace)

func _save_trace(enabled: bool) -> void:
	save.trace_enabled = enabled
	save.save_progress()
