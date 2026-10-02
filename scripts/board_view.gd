class_name BoardView
extends Control

signal cell_pressed(point: Vector2i)
const PALETTE: VisualPalette = preload("res://themes/palette.tres")
var model: BoardModel
var selected: Vector2i = Vector2i.ZERO
var trace_enabled: bool = false
var input_locked: bool = false
var visual_zoom: float = 1.0
var animated_point: Vector2i = Vector2i.ZERO
var dot_scale: float = 1.0
var rejected_point: Vector2i = Vector2i.ZERO
var reject_offset: float = 0.0
var flash_alpha: float = 0.0
var flash_pairs: Array = []
var celebration_alpha: float = 0.0
var _place_tween: Tween
var _reject_tween: Tween
@onready var trace_overlay: LineOverlay = $TraceOverlay
@onready var flash_overlay: LineOverlay = $FlashOverlay
@onready var celebration_overlay: LineOverlay = $CelebrationOverlay

func _ready() -> void:
	resized.connect(refresh)
	set_process(true)

func board_rect() -> Rect2:
	var side: float = minf(size.x, size.y) * 0.82 * visual_zoom
	return Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side)

func point_position(point: Vector2i) -> Vector2:
	var rect: Rect2 = board_rect()
	return rect.position + Vector2(point - Vector2i.ONE) * rect.size.x / float(model.size - 1)

func refresh() -> void:
	if model == null or not is_node_ready():
		return
	trace_overlay.show_lines(BoardModel.pair_lines(model.stones) if trace_enabled else [], model.size, board_rect(), PALETTE.trace)
	flash_overlay.show_lines(flash_pairs, model.size, board_rect(), PALETTE.reject)
	celebration_overlay.show_lines(BoardModel.pair_lines(model.stones), model.size, board_rect(), PALETTE.trace)
	flash_overlay.modulate.a = flash_alpha
	celebration_overlay.modulate.a = celebration_alpha
	queue_redraw()

func _process(_delta: float) -> void:
	if celebration_alpha > 0.0 or (_place_tween != null and _place_tween.is_running()) \
		or (_reject_tween != null and _reject_tween.is_running()):
		refresh()

func _gui_input(event: InputEvent) -> void:
	if input_locked or model == null:
		return
	if event is InputEventMouseButton:
		var click: InputEventMouseButton = event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			var rect: Rect2 = board_rect()
			var step: float = rect.size.x / float(model.size - 1)
			var relative: Vector2 = (click.position - rect.position) / step
			var point: Vector2i = Vector2i(roundi(relative.x) + 1, roundi(relative.y) + 1)
			if model.in_bounds(point) and click.position.distance_to(point_position(point)) <= minf(step * 0.45, 42.0):
				cell_pressed.emit(point)
				accept_event()

func animate_place(point: Vector2i) -> void:
	if _place_tween != null:
		_place_tween.kill()
	animated_point = point
	dot_scale = 0.85
	_place_tween = create_tween()
	_place_tween.tween_property(self, "dot_scale", 1.08, 0.07)
	_place_tween.tween_property(self, "dot_scale", 1.0, 0.08)

func animate_reject(point: Vector2i, pairs: Array) -> void:
	if _reject_tween != null:
		_reject_tween.kill()
	rejected_point = point
	flash_pairs = pairs
	flash_alpha = 1.0
	reject_offset = 0.0
	_reject_tween = create_tween()
	_reject_tween.tween_property(self, "reject_offset", -9.0, 0.08)
	_reject_tween.tween_property(self, "reject_offset", 0.0, 0.08)
	_reject_tween.tween_property(self, "flash_alpha", 0.0, 0.2)

func cancel_effects() -> void:
	if _place_tween != null:
		_place_tween.kill()
	if _reject_tween != null:
		_reject_tween.kill()
	flash_alpha = 0.0
	celebration_alpha = 0.0
	visual_zoom = 1.0
	dot_scale = 1.0
	selected = Vector2i.ZERO
	input_locked = false
	refresh()

func _draw() -> void:
	if model == null:
		return
	for y: int in range(1, model.size + 1):
		for x: int in range(1, model.size + 1):
			draw_circle(point_position(Vector2i(x, y)), 3.5, PALETTE.grid)
	for point: Vector2i in model.stones:
		var radius: float = 14.0 * (dot_scale if point == animated_point else 1.0)
		if point == selected:
			radius *= 1.15
			draw_arc(point_position(point), 24.0, 0.0, TAU, 48, PALETTE.muted, 2.0, true)
		draw_circle(point_position(point), radius, PALETTE.ink, true, -1.0, true)
	if flash_alpha > 0.0:
		var center: Vector2 = point_position(rejected_point) + Vector2(0.0, reject_offset)
		var color: Color = PALETTE.reject
		color.a = flash_alpha
		draw_line(center - Vector2(7, 7), center + Vector2(7, 7), color, 3.0, true)
		draw_line(center - Vector2(7, -7), center + Vector2(7, -7), color, 3.0, true)
