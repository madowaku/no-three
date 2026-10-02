extends SceneTree

var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(360, 800)
	var app: Control = (load("res://tests/ui_harness.tscn") as PackedScene).instantiate() as Control
	root.add_child(app)
	await process_frame
	app.developer_unlock = true
	app.show_puzzle(1)
	await process_frame
	await process_frame
	var board: BoardView = app.current_screen.board
	tap(board, Vector2i(3, 3))
	await process_frame
	verify(app.current_screen.completed, "touch places a dot at 360x800")
	app.show_puzzle(17)
	await process_frame
	await process_frame
	board = app.current_screen.board
	tap(board, Vector2i(1, 2))
	await process_frame
	verify(board.selected == Vector2i(1, 2), "touch selects exactly once")
	tap(board, Vector2i(4, 4))
	await process_frame
	verify(app.current_screen.completed, "touch moves and completes")
	app.queue_free()
	await process_frame
	print("TOUCH %s failures=%d" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func tap(board: BoardView, point: Vector2i) -> void:
	var physical_point: Vector2 = root.get_screen_transform() * board.get_global_transform_with_canvas() * board.point_position(point)
	for pressed: bool in [true, false]:
		var event: InputEventScreenTouch = InputEventScreenTouch.new()
		event.index = 0
		event.position = physical_point
		event.pressed = pressed
		Input.parse_input_event(event)

func verify(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
