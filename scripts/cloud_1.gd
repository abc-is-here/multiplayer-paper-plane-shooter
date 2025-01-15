extends Sprite2D

var speed : float = randf_range(80.0, 100.0)
@export var minX : float
@export var maxX : float

func _process(delta: float) -> void:
	position.x+=speed*delta
	
	if position.x > maxX:
		position.x = minX
