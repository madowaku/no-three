extends Control

signal stage_requested(stage_id: int)
signal back_requested
const CHAPTERS: Array[String] = ["THIRD", "TWO PER LINE", "NOT DIAGONAL", "INVISIBLE", "MOVE ONE"]
var _stages: Array[Dictionary] = []
var _save: SaveManager
var _developer_unlock: bool = false

func _ready() -> void:
	(%Back as Button).pressed.connect(func() -> void: back_requested.emit())
	if _save != null:
		_build_chapters()

func configure(stages: Array[Dictionary], save: SaveManager, developer_unlock: bool) -> void:
	_stages = stages
	_save = save
	_developer_unlock = developer_unlock
	if is_node_ready():
		_build_chapters()

func _build_chapters() -> void:
	var chapters: VBoxContainer = %Chapters
	for child: Node in chapters.get_children():
		child.queue_free()
	for chapter_index: int in range(CHAPTERS.size()):
		var chapter: VBoxContainer = VBoxContainer.new()
		chapter.name = "Chapter%d" % (chapter_index + 1)
		chapter.add_theme_constant_override("separation", 16)
		chapters.add_child(chapter)
		var caption: Label = Label.new()
		caption.text = "%02d   /   %s" % [chapter_index + 1, CHAPTERS[chapter_index]]
		caption.theme_type_variation = "CaptionLabel"
		chapter.add_child(caption)
		var row: HBoxContainer = HBoxContainer.new()
		row.name = "Stages"
		row.add_theme_constant_override("separation", 12)
		chapter.add_child(row)
		for stage_offset: int in range(4):
			var stage_id: int = chapter_index * 4 + stage_offset + 1
			var button: Button = Button.new()
			button.name = "Stage%03d" % stage_id
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size.y = 88
			button.disabled = not _developer_unlock and stage_id > _save.highest_unlocked_stage
			button.text = "•" if button.disabled else "%03d" % stage_id
			if _save.completed_stages.has(stage_id):
				button.text += "  ✓"
			button.tooltip_text = "%03d %s" % [stage_id, String(_stages[stage_id - 1]["name"])] if not button.disabled else ""
			button.pressed.connect(func() -> void: stage_requested.emit(stage_id))
			row.add_child(button)
