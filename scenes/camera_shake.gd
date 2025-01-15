extends Camera2D

var intensity: float = 3.0
var max_dur: float
var cur_dur: float

func _process(delta: float) -> void:
	if cur_dur<=0:
		return
	
	cur_dur = move_toward(cur_dur, 0.0, delta)
	var dur_prc = cur_dur/max_dur
	
	var x = randf_range(-dur_prc, dur_prc)
	var y = randf_range(-dur_prc, dur_prc)
	
	var pos = Vector2(x, y) * intensity
	
	offset = pos

func shake(skeDur: float, shakeInt: float):
	intensity = shakeInt
	cur_dur = skeDur
	max_dur = skeDur
