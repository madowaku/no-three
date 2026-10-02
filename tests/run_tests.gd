extends SceneTree

const GEOMETRY: Script = preload("res://tests/test_geometry.gd")
const BOARD: Script = preload("res://tests/test_board.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func _run() -> void:
	root.size = Vector2i(720, 1280)
	GEOMETRY.run(check)
	BOARD.run(check)
	DirAccess.make_dir_recursive_absolute("res://evidence")
	var save: SaveManager = SaveManager.new()
	save.save_path = "res://evidence/test_progress.cfg"
	save.trace_enabled = true
	save.complete_stage(1)
	save.complete_stage(1)
	var loaded: SaveManager = SaveManager.new()
	loaded.save_path = save.save_path
	loaded.load_progress()
	check(loaded.trace_enabled and loaded.highest_unlocked_stage == 2 and loaded.completed_stages == [1], "save round trip and duplicate completion")
	var app: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	app.save.save_path = "res://evidence/gameplay_progress.cfg"
	app.save.highest_unlocked_stage = 1
	root.add_child(app)
	await process_frame
	app.save.highest_unlocked_stage = 1
	app.save.completed_stages.clear()
	check(app.current_screen.name == "TitleScreen", "title boot")
	app.current_screen.play_requested.emit()
	await process_frame
	check(app.current_screen.name == "StageSelect", "title to stage select")
	var locked: Button = app.current_screen.get_node("Frame/Column/Chapters/Chapter1/Stages/Stage002")
	check(locked.disabled, "stage locked initially")
	app.show_puzzle(2)
	check(app.current_screen.name == "StageSelect", "locked stage cannot open")
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage_solutions.json"))
	for fixture: Dictionary in fixtures:
		var stage_id: int = int(fixture["id"])
		app.show_puzzle(stage_id)
		await process_frame
		await process_frame
		var puzzle: Control = app.current_screen
		var model: BoardModel = puzzle.model
		var board: BoardView = puzzle.board
		puzzle.set_trace(true)
		check(board.trace_overlay.segments.size() == BoardModel.pair_lines(model.stones).size(), "TRACE unique stage %03d" % stage_id)
		puzzle.reset()
		check(board.trace_enabled and model.history.is_empty(), "reset retains TRACE")
		if model.mode == "place":
			var before: Array[Vector2i] = model.stones.duplicate()
			var rejected: bool = false
			for y: int in range(1, model.size + 1):
				for x: int in range(1, model.size + 1):
					var point: Vector2i = Vector2i(x, y)
					if not rejected and not model.stones.has(point) and not model.is_valid_position(point):
						puzzle.handle_cell(point)
						check(model.stones == before and board.flash_alpha == 1.0, "rejection feedback")
						rejected = true
			for coordinate: Array in fixture["solution"]:
				var point: Vector2i = Vector2i(int(coordinate[0]), int(coordinate[1]))
				if not model.stones.has(point):
					click_cell(board, point)
		else:
			var source: Vector2i = Vector2i(int(fixture["move"][0][0]), int(fixture["move"][0][1]))
			var destination: Vector2i = Vector2i(int(fixture["move"][1][0]), int(fixture["move"][1][1]))
			check(not model.place(destination), "MOVE_ONE cannot add")
			click_cell(board, source)
			check(board.selected == source, "stone pickup")
			var rejected: bool = false
			for y: int in range(1, model.size + 1):
				for x: int in range(1, model.size + 1):
					var point: Vector2i = Vector2i(x, y)
					if not rejected and point != destination and not model.stones.has(point):
						click_cell(board, point)
						check(model.stones == model.initial and model.history.is_empty() and board.selected == source, "illegal move preserves selection and history")
						rejected = true
			click_cell(board, destination)
		check(model.is_complete() and puzzle.completed, "controller completion %03d" % stage_id)
		check(app.save.completed_stages.has(stage_id), "progress recorded %03d" % stage_id)
		await create_timer(1.3).timeout
		check(puzzle.clear_overlay.visible, "clear overlay %03d" % stage_id)
		if stage_id == 20:
			check((puzzle.clear_overlay.get_node("Next") as Button).disabled, "final stage has no next")
		puzzle.undo()
		check(not puzzle.completed and not model.is_complete() and not board.input_locked, "undo after clear %03d" % stage_id)
		if model.mode == "move_one":
			check(model.move_count == 0 and model.stones == model.initial, "move undo restores violation")
		puzzle.reset()
		check(model.stones == model.initial, "replay stage %03d" % stage_id)
		print("Stage %03d runtime PASS" % stage_id)
	check(app.save.highest_unlocked_stage == 20 and app.save.completed_stages.size() == 20, "full campaign unlock")
	app.show_stages()
	await process_frame
	await process_frame
	var final_button: Button = app.current_screen.get_node("Frame/Column/Chapters/Chapter5/Stages/Stage020")
	check(not final_button.disabled and final_button.text.contains("✓"), "completed stage select")
	app.queue_free()
	await process_frame
	print("TESTS %s checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func click_cell(board: BoardView, point: Vector2i) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = board.point_position(point)
	board._gui_input(event)
