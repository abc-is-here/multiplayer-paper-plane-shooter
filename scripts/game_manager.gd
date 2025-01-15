extends Node

var players: Array[Player] = []
var local_player: Player
var score_to_win: int = 5

var min_x: float = -400
var min_y: float = -230
var max_x: float = 400
var max_y: float = 230

@onready var camera_shake: Camera2D = $"../Camera2D"
@onready var end: Panel = $"../end"
@onready var win_text: Label = $"../end/win_text"
@onready var play_again: Button = $"../end/playAgain"

func get_random_pos() -> Vector2:
	return Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))

func on_player_die(player_id: int, attacker_id: int):
	var attacker = get_player(attacker_id)
	if not attacker:
		return
	attacker.increase_score(1)
	
	if attacker.score >= score_to_win:
		end_game_client.rpc(attacker.player_name)

func get_player(player_id: int) -> Player:
	for player in players:
		if player.player_id == player_id:
			return player
	return null

func reset_game():
	for player in players:
		player.respawn()
		player.score = 0
	disable_end.rpc()

@rpc("authority", "call_local", "reliable")
func disable_end():
	end.visible = false

@rpc("authority", "call_local", "reliable")
func end_game_client(winner_name: String):
	end.visible = true
	win_text.text = str(winner_name, " has won the game!")
	play_again.visible = multiplayer.is_server()

func _on_play_again_pressed():
	reset_game()
