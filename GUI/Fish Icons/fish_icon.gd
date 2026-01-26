extends AnimatedSprite2D

const max_size : Vector2 = Vector2(0.1, 0.1)

@export_range(0, 5) var type: int = 0
var time : float = 0.0
var vel : Vector2 = Vector2.ZERO
var accel : Vector2

func _ready() -> void:
	frame = type
	accel = Vector2.from_angle(randf_range(1.45, 1.55) * PI) * 0.7
	vel = accel * 2

func _process(delta: float) -> void:
	time += delta
	
	vel += 0.05 * accel * delta * 60
	position += vel * delta * 60
	
	if (time < 0.25):
		var s = time / 0.25
		scale = max_size * s
	elif (time < 1.75):
		scale = max_size
	elif (time < 2.0):
		visible = fposmod(time * 10, 1.0) < 0.5
	else:
		queue_free()
