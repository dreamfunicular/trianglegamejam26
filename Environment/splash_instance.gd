extends Node3D


func _ready():
	
	
	# play a sound
	var num = randi_range(0, 2) 
	$Sounds.get_child(num).pitch_scale = randf_range(0.9, 1.1)
	$Sounds.get_child(num).play()
	
	# TODO
	
	
	# do some particles
	# TODO
	
	
	# kill yourself
	# TODO
	await get_tree().create_timer(5).timeout
	queue_free()
