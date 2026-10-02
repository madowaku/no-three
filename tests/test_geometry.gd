extends RefCounted

static func run(check: Callable) -> void:
	var triples: Array = [
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(6, 1)],
		[Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 6)],
		[Vector2i(1, 1), Vector2i(2, 2), Vector2i(6, 6)],
		[Vector2i(1, 1), Vector2i(3, 2), Vector2i(5, 3)],
		[Vector2i(1, 1), Vector2i(2, 3), Vector2i(3, 5)],
		[Vector2i(1, 5), Vector2i(3, 3), Vector2i(5, 1)],
	]
	for triple: Array in triples:
		check.call(BoardModel.are_collinear(triple[0], triple[1], triple[2]), "integer angle")
	check.call(not BoardModel.are_collinear(Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 1)), "non collinear")
	check.call(BoardModel.canonical_line_key(Vector2i(1, 1), Vector2i(3, 2)) == BoardModel.canonical_line_key(Vector2i(5, 3), Vector2i(3, 2)), "canonical reversed pair")
	var points: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3), Vector2i(4, 4)]
	check.call(BoardModel.pair_lines(points).size() == 1, "pair line deduplication")
	check.call(BoardModel.get_violation_lines(points).size() == 1, "violation deduplication")
