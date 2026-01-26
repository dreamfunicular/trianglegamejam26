extends Container

var stamina: float = 10.0
var display_stamina : float = 10.0

func use_stamina(amount: float) -> bool:
	if stamina - amount >= 0.0:
		stamina -= amount
		return true
	return false

func _process(delta: float) -> void:
	stamina = move_toward(stamina, 10.0, delta * 60 * 0.01)
	display_stamina = lerp(display_stamina, stamina, 60 * delta * 0.5)
	$AnimatedSprite2D.frame = clamp(floor(display_stamina * 2), 0, 20)
