extends GPUParticles3D

@onready var player = get_tree().root.find_child("Player", true, false)

func _physics_process(_delta: float) -> void:
	if (player):
		position = player.position
		position.y = min(position.y, -128)
