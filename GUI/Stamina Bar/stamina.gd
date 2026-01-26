extends Container

var stamina: float = 10.0

func use_stamina(amount: float) -> bool:
	if stamina - amount >= 0.0:
		stamina -= amount
		return true
	return false

func _process(delta: float) -> void:
	stamina = move_toward(stamina, 10.0, delta * 60 * 0.1)
	$AnimatedSprite2D.frame = clamp(floor(stamina * 2), 0, 20)
