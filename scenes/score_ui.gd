extends Panel

var game_manager
@onready var player_scores: Label = $PlayerScores

func _ready() -> void:
	game_manager = get_tree().get_current_scene().get_node("GameManager")
	

func _process(_delta: float) -> void:
	player_scores.text = ""
	for Player in game_manager.players:
		var text = str(Player.player_name, " - ", Player.score, "\n")
		player_scores.text += text
