extends Node

const MAX_CLIENTS: int = 4

@onready var net_ui: Panel = $netUI
@onready var port_inp: LineEdit = $netUI/VBoxContainer/PortInp
@onready var ipinp: LineEdit = $netUI/VBoxContainer/IPinp
@onready var spawn_nodes: Node = $spawn_nodes

var loc_user: String
var player_scene = preload("res://scenes/player.tscn")
var spawn_range_x: float = 350.0
var spawn_range_y: float = 200.0

func start_host() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_inp.text), MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_on_player_connect)
	multiplayer.peer_disconnected.connect(_on_player_disconnect)
	
	_on_player_connect(multiplayer.get_unique_id())
	
	net_ui.visible = false

func start_client() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ipinp.text, int(port_inp.text))
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _on_player_connect(id: int) -> void:
	print("Player %s joined the game." % id)
	var player = player_scene.instantiate()
	player.player_id = id
	player.name = str(id)
	spawn_nodes.add_child(player, true)

func _on_player_disconnect(id: int) -> void:
	print("Player %s left the game." % id)
	if not spawn_nodes.has_node(str(id)):
		return
	
	spawn_nodes.get_node(str(id)).queue_free()

func _connected_to_server() -> void:
	print("Connected to the server")
	net_ui.visible = false

func _connection_failed() -> void:
	print("Connection failed")

func _server_disconnected() -> void:
	print("Server disconnected")
	net_ui.visible = true

func _on_name_inp_text_changed(new_text: String) -> void:
	loc_user = new_text
