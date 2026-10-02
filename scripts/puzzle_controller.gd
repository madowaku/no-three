extends Control

signal stage_completed(stage_id: int)
signal next_requested(stage_id: int)
signal stages_requested
signal trace_changed(enabled: bool)
var model: BoardModel = BoardModel.new()
var stage_id: int = 1
var trace_enabled: bool = false
var completed: bool = false
var _celebration: Tween
@onready var board: BoardView = %Board
@onready var counter: Label = %Counter
@onready var trace_button: Button = %Trace
@onready var undo_button: Button = %Undo
@onready var controls: VBoxContainer = %Controls
@onready var clear_overlay: VBoxContainer = %ClearOverlay
@onready var audio: AudioFeedback = $AudioFeedback

func _ready() -> void:
	board.model = model
	board.cell_pressed.connect(handle_cell)
	trace_button.toggled.connect(set_trace)
	undo_button.pressed.connect(undo)
	(%Reset as Button).pressed.connect(reset)
	(%StageSelect as Button).pressed.connect(func() -> void: stages_requested.emit())
	clear_overlay.next_requested.connect(func() -> void: next_requested.emit(stage_id + 1))
	clear_overlay.replay_requested.connect(reset)
	clear_overlay.stages_requested.connect(func() -> void: stages_requested.emit())
	clear_overlay.undo_requested.connect(undo)
	_refresh()

func configure(stage: Dictionary, enabled: bool) -> void:
	stage_id = int(stage["id"])
	model.configure(stage)
	trace_enabled = enabled
	if is_node_ready():
		(%StageNumber as Label).text = "%03d" % stage_id
		(%StageName as Label).text = String(stage["name"])
		(%Chapter as Label).text = String(stage["chapter"])
		(%Instruction as Label).text = "PLACE THE LAST DOT" if stage_id == 1 else ("MOVE ONE DOT" if stage_id == 17 else "")
		trace_button.set_pressed_no_signal(enabled)
		board.trace_enabled = enabled
		clear_overlay.configure(stage_id == 20)
		_refresh()

func handle_cell(point: Vector2i) -> void:
	if completed or board.input_locked:
		return
	if model.stones.has(point):
		if model.mode == "move_one":
			board.selected = Vector2i.ZERO if board.selected == point else point
			audio.play("pickup")
			board.refresh()
		return
	if model.mode == "move_one" and board.selected == Vector2i.ZERO:
		return
	var accepted: bool = model.place(point) if model.mode == "place" else model.move_stone(board.selected, point)
	if not accepted:
		board.animate_reject(point, model.preview_violations(point, board.selected))
		audio.play("reject")
		return
	board.selected = Vector2i.ZERO
	board.animate_place(point)
	audio.play("place")
	_refresh()
	if model.is_complete():
		_complete()

func set_trace(enabled: bool) -> void:
	trace_enabled = enabled
	board.trace_enabled = enabled
	trace_button.text = "TRACE ON" if enabled else "TRACE OFF"
	board.refresh()
	trace_changed.emit(enabled)

func undo() -> void:
	if model.undo():
		_cancel_clear()
		_refresh()

func reset() -> void:
	model.reset()
	_cancel_clear()
	_refresh()

func _cancel_clear() -> void:
	if _celebration != null:
		_celebration.kill()
	completed = false
	clear_overlay.hide()
	controls.show()
	board.cancel_effects()

func _refresh() -> void:
	counter.text = "%d / %d" % [model.stones.size(), model.target]
	undo_button.disabled = model.history.is_empty()
	trace_button.text = "TRACE ON" if trace_enabled else "TRACE OFF"
	board.refresh()

func _complete() -> void:
	completed = true
	board.input_locked = true
	board.celebration_alpha = 1.0
	audio.play("clear")
	stage_completed.emit(stage_id)
	_celebration = create_tween()
	_celebration.tween_property(board, "visual_zoom", 0.94, 0.2).set_trans(Tween.TRANS_SINE)
	_celebration.tween_interval(0.5)
	_celebration.tween_property(board, "celebration_alpha", 0.0, 0.3)
	_celebration.tween_callback(func() -> void:
		controls.hide()
		clear_overlay.show()
		clear_overlay.modulate.a = 0.0
	)
	_celebration.tween_property(clear_overlay, "modulate:a", 1.0, 0.2)
	_celebration.tween_callback(board.refresh)
