extends VBoxContainer

signal next_requested
signal replay_requested
signal stages_requested
signal undo_requested

func _ready() -> void:
	(%Next as Button).pressed.connect(func() -> void: next_requested.emit())
	(%Replay as Button).pressed.connect(func() -> void: replay_requested.emit())
	(%Select as Button).pressed.connect(func() -> void: stages_requested.emit())
	(%UndoClear as Button).pressed.connect(func() -> void: undo_requested.emit())

func configure(final_stage: bool) -> void:
	(%Next as Button).text = "ALL COMPLETE" if final_stage else "NEXT  →"
	(%Next as Button).disabled = final_stage
