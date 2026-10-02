class_name LineOverlay
extends Node2D

var segments: Array = []
var line_color: Color
var line_width: float = 2.0

func show_lines(pairs: Array, board_size: int, board_rect: Rect2, color: Color) -> void:
	segments.clear()
	line_color = color
	for pair: Array in pairs:
		var a: Vector2i = pair[0]
		var b: Vector2i = pair[1]
		var intersections: Array[Vector2] = []
		var direction: Vector2 = Vector2(b - a)
		# Only rendering uses floats. Rule evaluation is entirely integer based.
		if direction.x != 0.0:
			for edge_x: float in [1.0, float(board_size)]:
				var y: float = a.y + (edge_x - a.x) * direction.y / direction.x
				if y >= 1.0 and y <= board_size:
					intersections.append(Vector2(edge_x, y))
		if direction.y != 0.0:
			for edge_y: float in [1.0, float(board_size)]:
				var x: float = a.x + (edge_y - a.y) * direction.x / direction.y
				var point: Vector2 = Vector2(x, edge_y)
				if x >= 1.0 and x <= board_size and not intersections.has(point):
					intersections.append(point)
		if intersections.size() >= 2:
			var spacing: float = board_rect.size.x / float(board_size - 1)
			segments.append([board_rect.position + (intersections[0] - Vector2.ONE) * spacing,
				board_rect.position + (intersections[1] - Vector2.ONE) * spacing])
	queue_redraw()

func _draw() -> void:
	for segment: Array in segments:
		draw_line(segment[0], segment[1], line_color, line_width, true)
