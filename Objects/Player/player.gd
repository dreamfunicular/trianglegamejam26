extends CharacterBody3D

const GRAV = -9.8

const CAMERA_ROLL_PERCENT = 0.5

const ROLL_SENSE = 0.001
const ROLL_NORMALIZE_SPEED = 4

const MOUSE_SENSE = 0.003

@onready var pitch_pivot = $PitchPivot
@onready var camera = $PitchPivot/Camera3D
@onready var model = $PitchPivot/Placeholder

# Camera settings (COME BACK TO THESE FOR SPEED STUFF)
const CAMERA_DISTANCE = 5.0
const CAMERA_HEIGHT = 1.0

var roll : float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.position = Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	
	velocity = -transform.basis.z * 50.0

func _input(event) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSE)
		pitch_pivot.rotate_x(-event.relative.y * MOUSE_SENSE)
		roll += event.relative.x * ROLL_SENSE
		#rotation.x = clamp(rotation.x, -PI/2, PI/2) # Uncomment to disable upside down flying

func _physics_process(delta) -> void:
	roll = clamp(lerp(roll, 0.0, 1.0 - exp(-ROLL_NORMALIZE_SPEED * delta)), -PI/8, PI/8)
	model.rotation.x = roll
	rotation.z = -roll * CAMERA_ROLL_PERCENT
	
	velocity.y += GRAV * delta
	
	var desired_dir = -pitch_pivot.global_transform.basis.z
	
	#var speed_weight = clamp(20.0 / max(velocity.length(), 1.0), 0.05, 1.0) * 0.9
	var speed_weight = ease(min(velocity.length() / 20, 1.0), 0.3)
	velocity = velocity.lerp(desired_dir * velocity.length(), speed_weight * 0.1 * 60 * delta)
	
	var dot_weight = clamp(velocity.normalized().dot(desired_dir.normalized()), 0.05, 1.0) * 0.1
	
	if Input.is_action_just_pressed("ui_accept"):
		velocity = -transform.basis.z * 30.0
	
	move_and_slide()
