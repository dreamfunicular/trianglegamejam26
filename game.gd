extends Node3D

signal reload

var flock

# Called when the node enters the scene tree for the first time.
func ready() -> void:
	print("Help?")

# Called every frame. 'delta' is the elapsed time since the previous frame.
var flockSpeed = 5
func process(delta: float) -> void:
	flock.visible = false
