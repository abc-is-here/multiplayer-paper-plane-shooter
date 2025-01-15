extends CharacterBody2D
class_name Player

@export var player_name: String
@export var player_id: int = 1:
	set(id):
		player_id = id
		$InputSynchronizer.set_multiplayer_authority(id)

@export var max_speed: float = 150.0
@export var turn_rate: float = 2.5

@onready var muzzle = $muzzle
@onready var input_synchronizer = $InputSynchronizer
@onready var shadow = $shade
@onready var respawn_timer: Timer = $respawnTimer
@onready var audio: AudioStreamPlayer = $Audio
@onready var sprite: Sprite2D = $sprite
@onready var hit_particles: CPUParticles2D = $hitParticles

const PLANE_EXPLODE = preload("res://Audio/PlaneExplode.wav")
const PLANE_HIT = preload("res://Audio/PlaneHit.wav")
const PLANE_SHOOT = preload("res://Audio/PlaneShoot.wav")

@export var cur_weapon_heat : float = 0.0
@export var max_weapon_heat : float = 100.0
var weapon_heat_increase_rate : float = 7.0
var weapon_heat_cool_rate : float = 25.0
var weapon_heat_cap_wait_time : float = 1.5
var weapon_heat_waiting : bool = false

var throttle: float = 0.0
@export var shoot_rate: float = 0.1
var last_shoot: float = 0.0
var proj_scene = preload("res://scenes/projectile.tscn")

var game_manager

var border_min_x: float = -400.0
var border_max_x: float = 400.0
var border_min_y: float = -230.0
var border_max_y: float = 230.0

@export var cur_hp : int = 100
@export var max_hp : int = 100
@export var score : int = 0
var last_attacker_id : int
var is_alive : bool = true

func _ready() -> void:
	game_manager = get_tree().get_current_scene().get_node("GameManager")
	game_manager.players.append(self)
	
	if $InputSynchronizer.is_multiplayer_authority():
		game_manager.local_player = self
		
		var net_manager = get_tree().get_current_scene().get_node("net")
		set_player_name.rpc(net_manager.loc_user)
	
	if multiplayer.is_server():
		position = game_manager.get_random_pos()

@rpc("any_peer", "call_local", "reliable")
func set_player_name(new_name: String):
	player_name = new_name

func _process(delta: float) -> void:
	shadow.global_position = position + Vector2(0, 20)
	if multiplayer.is_server():
		check_border()
		try_shoot()
		_manage_weapon_heat(delta)

func _physics_process(delta: float) -> void:
	if multiplayer.is_server() and is_alive:
		_move(delta)

func _move(delta: float) -> void:
	rotate(input_synchronizer.turn * turn_rate * delta)
	throttle += input_synchronizer.throttle * delta
	throttle = clamp(throttle, 0.0, 1.0)
	velocity = -transform.y * throttle * max_speed
	move_and_slide()

func try_shoot() -> void:
	if not input_synchronizer.shoot:
		return
	
	if cur_weapon_heat >= max_weapon_heat:
		return
	
	if Time.get_unix_time_from_system() - last_shoot < shoot_rate:
		return
		
	last_shoot = Time.get_unix_time_from_system()
	
	var proj = proj_scene.instantiate() 
	proj.position = muzzle.global_position
	proj.rotation = rotation + deg_to_rad(randf_range(-2, 2))
	proj.owner_id = player_id
	get_tree().current_scene.get_node("net/spawn_nodes").add_child(proj, true)
	
	play_shoot.rpc()
	
	cur_weapon_heat+=weapon_heat_increase_rate
	
	cur_weapon_heat = clamp(cur_weapon_heat, 0, max_weapon_heat)

@rpc("authority", "call_local", "reliable")
func play_shoot():
	audio.stream = PLANE_SHOOT
	audio.play()

func take_damage(damage_amt: int, attacker_player_id: int) -> void:
	cur_hp -= damage_amt
	last_attacker_id = attacker_player_id
	play_damage.rpc()
	if cur_hp <= 0:
		die()

@rpc("authority", "call_local", "reliable")
func play_damage():
	audio.stream = PLANE_SHOOT
	audio.play()
	
	sprite.modulate = Color(1,0,0)
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color(1,1,1)
	if $InputSynchronizer.is_multiplayer_authority():
		game_manager.camera_shake.shake(0.1, 3.0)
		
	hit_particles.emitting = true

func die():
	is_alive = false
	position = Vector2(0, 9999)
	respawn_timer.start(2)
	game_manager.on_player_die(player_id, last_attacker_id)
	play_die.rpc()

@rpc("authority", "call_local", "reliable")
func play_die():
	if $InputSynchronizer.is_multiplayer_authority():
		game_manager.camera_shake.shake(0.5, 7.0)
	audio.stream = PLANE_EXPLODE
	audio.play()

func respawn():
	is_alive = true
	cur_hp = max_hp
	throttle = 0.0
	rotation = 0
	last_attacker_id = 0
	position = game_manager.get_random_pos()

func _manage_weapon_heat(delta):
	if cur_weapon_heat < max_weapon_heat:
		cur_weapon_heat -= weapon_heat_cool_rate * delta
	
		if cur_weapon_heat < 0:
			cur_weapon_heat = 0
	
		return
	
	if weapon_heat_waiting:
		return
	
	weapon_heat_waiting = true
	await get_tree().create_timer(weapon_heat_cap_wait_time).timeout
	weapon_heat_waiting = false
	cur_weapon_heat -= weapon_heat_cool_rate*delta
	

func check_border() -> void:
	if position.x < border_min_x:
		position.x = border_max_x
	elif position.x > border_max_x:
		position.x = border_min_x
	if position.y < border_min_y:
		position.y = border_max_y
	elif position.y > border_max_y:
		position.y = border_min_y

func increase_score(amount: int):
	score+=amount
