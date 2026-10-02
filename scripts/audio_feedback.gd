class_name AudioFeedback
extends Node

const SOUNDS: Dictionary = {
	"place": preload("res://assets/audio/place.wav"),
	"reject": preload("res://assets/audio/reject.wav"),
	"clear": preload("res://assets/audio/clear.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

func _ready() -> void:
	for index: int in range(4):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		_players.append(player)

func play(cue: String) -> void:
	var player: AudioStreamPlayer = _players[_next_player]
	player.stream = SOUNDS[cue]
	player.play()
	_next_player = (_next_player + 1) % _players.size()
