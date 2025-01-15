extends MultiplayerSynchronizer

@export var throttle: float
@export var turn: float
@export var shoot: bool

func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_physics_process(false)

func _physics_process(_delta: float) -> void:
	throttle = Input.get_axis("throttle_down", "Throttle_up")
	turn = Input.get_axis("turn_left", "turn_right")
	shoot = Input.is_action_pressed("shoot")
