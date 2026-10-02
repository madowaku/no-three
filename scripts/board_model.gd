class_name BoardModel
extends RefCounted

var size: int = 3
var target: int = 6
var mode: String = "place"
var stones: Array[Vector2i] = []
var initial: Array[Vector2i] = []
var history: Array = []
var move_count: int = 0

static func are_collinear(a: Vector2i, b: Vector2i, c: Vector2i) -> bool:
	return (b.x - a.x) * (c.y - a.y) == (b.y - a.y) * (c.x - a.x)

static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var remainder: int = a % b
		a = b
		b = remainder
	return a

static func canonical_line_key(a: Vector2i, b: Vector2i) -> String:
	if a == b:
		return ""
	var aa: int = b.y - a.y
	var bb: int = a.x - b.x
	var cc: int = -(aa * a.x + bb * a.y)
	var divisor: int = _gcd(_gcd(absi(aa), absi(bb)), absi(cc))
	@warning_ignore("integer_division")
	aa = aa / divisor
	@warning_ignore("integer_division")
	bb = bb / divisor
	@warning_ignore("integer_division")
	cc = cc / divisor
	if aa < 0 or (aa == 0 and bb < 0):
		aa = -aa
		bb = -bb
		cc = -cc
	return "%d:%d:%d" % [aa, bb, cc]

static func pair_lines(points: Array[Vector2i]) -> Array:
	var unique: Dictionary = {}
	for i: int in range(points.size()):
		for j: int in range(i + 1, points.size()):
			var key: String = canonical_line_key(points[i], points[j])
			unique[key] = [points[i], points[j]]
	return unique.values()

static func get_violation_lines(points: Array[Vector2i]) -> Array:
	var unique: Dictionary = {}
	for i: int in range(points.size()):
		for j: int in range(i + 1, points.size()):
			for k: int in range(j + 1, points.size()):
				if are_collinear(points[i], points[j], points[k]):
					unique[canonical_line_key(points[i], points[j])] = [points[i], points[j]]
	return unique.values()

func configure(stage: Dictionary) -> void:
	size = int(stage["size"])
	target = int(stage["target"])
	mode = String(stage["mode"])
	initial.clear()
	for coordinate: Array in stage["initial"]:
		initial.append(Vector2i(int(coordinate[0]), int(coordinate[1])))
	reset()

func in_bounds(point: Vector2i) -> bool:
	return point.x >= 1 and point.y >= 1 and point.x <= size and point.y <= size

func is_valid_position(point: Vector2i, excluded: Vector2i = Vector2i.ZERO) -> bool:
	if not in_bounds(point) or stones.has(point):
		return false
	var preview: Array[Vector2i] = stones.duplicate()
	preview.erase(excluded)
	preview.append(point)
	return get_violation_lines(preview).is_empty()

func preview_violations(point: Vector2i, excluded: Vector2i = Vector2i.ZERO) -> Array:
	var preview: Array[Vector2i] = stones.duplicate()
	preview.erase(excluded)
	preview.append(point)
	return get_violation_lines(preview)

func place(point: Vector2i) -> bool:
	if mode != "place" or stones.size() >= target or not is_valid_position(point):
		return false
	_snapshot()
	stones.append(point)
	return true

func move_stone(source: Vector2i, destination: Vector2i) -> bool:
	if mode != "move_one" or move_count != 0 or not stones.has(source):
		return false
	if not is_valid_position(destination, source):
		return false
	_snapshot()
	stones[stones.find(source)] = destination
	move_count += 1
	return true

func _snapshot() -> void:
	history.append({"stones": stones.duplicate(), "move_count": move_count})

func undo() -> bool:
	if history.is_empty():
		return false
	var previous: Dictionary = history.pop_back()
	stones.assign(previous["stones"])
	move_count = int(previous["move_count"])
	return true

func reset() -> void:
	stones = initial.duplicate()
	history.clear()
	move_count = 0

func is_complete() -> bool:
	return stones.size() == target and get_violation_lines(stones).is_empty() \
		and (mode == "place" or move_count == 1)
