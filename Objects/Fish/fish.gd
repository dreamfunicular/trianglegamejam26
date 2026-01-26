extends CharacterBody3D

func get_id() -> int:
	return 5

func die() -> void:
	queue_free()
