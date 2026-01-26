extends Node3D

@onready var fish = preload("res://Objects/Fish/Fish.tscn")

func _ready() -> void:
	for i in 500:
		var new_fish = fish.instantiate()
		add_sibling.call_deferred(new_fish)
		new_fish.position = Vector3(randf_range(-100, 100), randf_range(-60, -10), randf_range(-100, 100))
