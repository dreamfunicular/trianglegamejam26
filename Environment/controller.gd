extends Node3D

var main

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main = %main

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reload() -> void:
	print("You lose! You get nothing! Good day sir!")
	main.queue_free()
	var mainScene = preload("res://main.tscn")
	main = mainScene.instantiate()
	main.connect("reload", reload)
	add_child(main)
	
