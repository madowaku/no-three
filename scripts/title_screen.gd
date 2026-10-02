extends Control

signal play_requested
signal stages_requested

@onready var play_button: Button = %Play

func _ready() -> void:
	play_button.pressed.connect(func() -> void: play_requested.emit())
	(%Stages as Button).pressed.connect(func() -> void: stages_requested.emit())

func set_progress(unlocked: int, complete_count: int) -> void:
	play_button.text = "BEGIN" if unlocked == 1 and complete_count == 0 else "CONTINUE"
	(%Progress as Label).text = "%02d / 20 COMPLETE" % complete_count
