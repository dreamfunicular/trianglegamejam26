extends Node3D

@export var numFishToGenerate = 500
@export var time = 8.0

var minZ = -512

@export var width = 768
@export var depth = 1024

var timer : Timer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = %timer
	timer.wait_time = time

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func shift():
	minZ += 512

func generateFish() -> void:
	var fish := preload("res://Objects/fish.tscn")
		
	for i in numFishToGenerate:
		var fishX = randf_range(- width / 2, width / 2)
		var fishZ = randf_range(minZ - depth / 2, minZ + depth / 2)
		
		var newFish = fish.instantiate()
		newFish.position = Vector3(fishX, 0, fishZ)
		add_child(newFish)
		
