extends Control

const PALETTE: VisualPalette = preload("res://themes/palette.tres")

func _draw() -> void:
	var center: Vector2 = size * 0.5
	for point: Vector2 in [Vector2(-64,-36), Vector2(0,-36), Vector2(-64,28), Vector2(64,28), Vector2(0,92)]:
		draw_circle(center + point - Vector2(0, 28), 10.0, PALETTE.ink, true, -1.0, true)
