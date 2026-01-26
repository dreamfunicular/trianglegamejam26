extends Node3D

signal reload 

var flock
var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flock = %flock  
	player = %Player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	flock.position.z += 50 * delta
	
	if (flock.position.distance_to(player.position) > 600):
		print("Too far from the flock!")
		on_player_dead()

func on_player_dead() -> void:
	emit_signal("reload")
