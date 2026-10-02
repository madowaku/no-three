extends RefCounted

static func run(check: Callable) -> void:
	var model: BoardModel = BoardModel.new()
	model.configure({"size": 6, "target": 12, "mode": "place", "initial": [[1, 1], [3, 2]]})
	check.call(not model.place(Vector2i(5, 3)), "non 45 degree reject")
	check.call(model.history.is_empty(), "reject does not add history")
	check.call(not model.place(Vector2i.ZERO), "bounds reject")
	check.call(not model.place(Vector2i(1, 1)), "duplicate reject")
	check.call(model.place(Vector2i(1, 2)), "valid placement")
	check.call(model.undo() and model.stones.size() == 2, "snapshot undo")
	check.call(not model.undo(), "initial undo boundary")
	model.place(Vector2i(2, 1))
	model.reset()
	check.call(model.stones == model.initial and model.history.is_empty(), "reset clears history")
	model.configure({"size": 3, "target": 6, "mode": "place", "initial": [[1, 1], [2, 1]]})
	check.call(not model.place(Vector2i(3, 1)), "horizontal reject")
	model.configure({"size": 3, "target": 6, "mode": "place", "initial": [[1, 1], [1, 2]]})
	check.call(not model.place(Vector2i(1, 3)), "vertical reject")
