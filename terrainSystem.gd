extends Node3D

var checkpoint
var river
var terrain
var fishgrid

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	checkpoint = %checkpoint
	river = %river
	terrain = %terrain
	fishgrid = %fishgrid

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_checkpoint_body_entered(body: Node3D) -> void:
	if (body.name != "Player"):
		return
	print("Entered!")
	checkpoint.position = checkpoint.position + Vector3(0, 0, 512)
	river.position = river.position + Vector3(0, 0, 512)
	terrain.shift()
	fishgrid.shift()
