extends CharacterBody3D

const GRAV = -15.0

const CAMERA_ROLL_PERCENT = 0.5

const ROLL_SENSE = 0.002
const ROLL_NORMALIZE_SPEED = 4

const MOUSE_SENSE = 0.003

@onready var pitch_pivot = $PitchPivot
@onready var camera = $PitchPivot/Camera3D
@onready var model = $PitchPivot/Gannet2

# Camera settings (COME BACK TO THESE FOR SPEED STUFF)
const CAMERA_DISTANCE = 5.0
const CAMERA_HEIGHT = 1.0

var roll : float = 0.0

@export var flightBlendPath: String
@export var flappingBlendPath: String

var in_water : bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.position = Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	
	velocity = -transform.basis.z * 50.0

func _input(event) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSE)
		pitch_pivot.rotate_x(-event.relative.y * MOUSE_SENSE)
		roll += event.relative.x * ROLL_SENSE

func _physics_process(delta) -> void:
	var wing_amount = clamp(1.2 - pitch_pivot.global_transform.basis.z.normalized().y * 1.4, 0.0, 1.0)
	model.get_anim_tree().set(flightBlendPath, wing_amount);
	model.get_anim_tree().set(flappingBlendPath, 0)
	
	roll = clamp(lerp(roll, 0.0, 1.0 - exp(-ROLL_NORMALIZE_SPEED * delta)), -PI/4, PI/4)
	model.rotation.z = -roll
	rotation.z = -roll * CAMERA_ROLL_PERCENT
	
	velocity.y += GRAV * delta
	
	var desired_dir = -pitch_pivot.global_transform.basis.z
	
	#var speed_weight = clamp(20.0 / max(velocity.length(), 1.0), 0.05, 1.0) * 0.9
	var speed_weight = ease(min(velocity.length() / 20, 1.0), 0.3)
	velocity = velocity.lerp(desired_dir * velocity.length(), speed_weight * 0.1 * 60 * delta)
	
	#var dot_weight = velocity.normalized().dot(desired_dir.normalized())
	
	if Input.is_action_just_pressed("ui_accept"):
		velocity = (-transform.basis.z + pitch_pivot.transform.basis.y).normalized() * 30.0
	
	
	
	if (position.y < 0 && not in_water):
		enter_water()
		
	if (position.y > 0 && in_water):
		exit_water()
	
	if in_water:
		velocity.y = min(velocity.y + 1.5, 100)
		
	move_and_slide()


func set_shader_value(param: String, value):
	$UnderwaterEffect.get_child(0).material.set_shader_parameter(param, value);


func enter_water():
	in_water = true
	
	var tween = get_tree().create_tween()
	tween.set_ease(tween.EASE_IN) # idk if this does anything
	
	tween.tween_method(func(value): set_shader_value("activate", value), 0.0, 1.0, 0.1); # args are: (method to call / start value / end value / duration of animation)
	
	## TODO play any sound effect
	
	# do any sound adjustments

func exit_water():
	in_water = false
	
	var tween = get_tree().create_tween()
	tween.set_ease(tween.EASE_IN)
	tween.tween_method(func(value): set_shader_value("activate", value), 1.0, 0.0, 0.1); # args are: (method to call / start value / end value / duration of animation)
	
	## TODO play any sound effect
	
	# do any sound adjustments
