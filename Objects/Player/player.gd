extends CharacterBody3D

const GRAV = -15.0

const CAMERA_ROLL_PERCENT = 0.5

const ROLL_SENSE = 0.002
const ROLL_NORMALIZE_SPEED = 4

const MOUSE_SENSE_MAX = 0.004
const MOUSE_SENSE_MIN = 0.002
const TURN_CLAMP_MAX = PI/36
const TURN_CLAMP_MIN = PI/72

@onready var pitch_pivot = $PitchPivot
@onready var camera = $PitchPivot/Camera3D
@onready var model = $PitchPivot/Gannet2

# Camera settings (COME BACK TO THESE FOR SPEED STUFF)
const CAMERA_DISTANCE = 5.0
const CAMERA_HEIGHT = 2.0

var roll : float = 0.0

@export var flight_blend_path: String
@export var air_state_playback_path: String
const FLIGHT_STATE_NAME : String = "Flight"
const FLAP_STATE_NAME : String = "Flap"

var is_bird_surfacing : bool = false
var camera_in_water : bool = false

enum PlayerStates {
	FLY,
	DIVE,
	FLOAT,
}
var state: PlayerStates = PlayerStates.FLY

@export var flap_blend: Curve
const FLAP_POWER = 1.5
const FLAP_DUR = 1.75
const FLAP_COOLDOWN = 0.5
var flap_time = -FLAP_COOLDOWN

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.position = Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	
	velocity = -transform.basis.z * 50.0

func _input(event) -> void:
	if event is InputEventMouseMotion:
		var mouse_sense = lerp(MOUSE_SENSE_MAX, MOUSE_SENSE_MIN, get_speed_lerp())
		var turn_clamp = lerp(TURN_CLAMP_MAX, TURN_CLAMP_MIN, get_speed_lerp())
		rotate_y(clamp(-event.relative.x * mouse_sense, -turn_clamp, turn_clamp))
		pitch_pivot.rotate_x(clamp(-event.relative.y * mouse_sense, -turn_clamp, turn_clamp))
		roll += event.relative.x * ROLL_SENSE

func update_cam():
	if (camera.global_position.y < 0 && not camera_in_water):
		camera_enter_water()
	
	if (camera.global_position.y > 0 && camera_in_water):
		camera_exit_water()

func update_state():
	match state:
		PlayerStates.FLY:
			if position.y < 0:
				state = PlayerStates.DIVE
				is_bird_surfacing = false
				## TODO: Add Sound Effect
				## TODO: Add Particles
		
		PlayerStates.DIVE:
			if position.y > 0:
				state = PlayerStates.FLY

func get_speed_lerp() -> float:
	#if velocity.length() > 50: print("maxed out " + str(randi_range(0, 9)))
	return min(1.0, velocity.length() / 50)

func set_wing_amt(wing_amount: float) -> void:
	model.get_anim_tree().set(flight_blend_path, wing_amount);

func _physics_process(delta) -> void:
	# updates all info about where the bird and the camera are
	update_state()
	update_cam()
	
	var wing_amt_height = clamp(position.y/2.0, 0.0, 1.0)
	var wing_amt_dive = clamp(1.2 - pitch_pivot.global_transform.basis.z.normalized().y * 1.4, 0.0, 1.0)
	var wing_amt_speed = clamp(1 - (velocity.length() - 40)/50, 0.0, 1.0) * 0.3 + 0.7
	set_wing_amt(wing_amt_height * wing_amt_dive * wing_amt_speed)
	#
	roll = clamp(lerp(roll, 0.0, 1.0 - exp(-ROLL_NORMALIZE_SPEED * delta)), -PI/4, PI/4)
	model.rotation.z = -roll
	rotation.z = -roll * CAMERA_ROLL_PERCENT
	
	if (flap_time > -FLAP_COOLDOWN):
		flap_time -= delta
		if (flap_time < -FLAP_COOLDOWN):
			flap_time = -FLAP_COOLDOWN
	
	# flying bird only code
	match state:
		PlayerStates.FLY:
			velocity.y += GRAV * delta
			
			if (flap_time > 0):
				var percent_flap = flap_blend.sample(1 - flap_time/FLAP_DUR)
				velocity += percent_flap * (-transform.basis.z + pitch_pivot.transform.basis.y).normalized() * FLAP_POWER

			var desired_dir = -pitch_pivot.global_transform.basis.z
			
			#var speed_weight = clamp(20.0 / max(velocity.length(), 1.0), 0.05, 1.0) * 0.9
			var speed_weight = ease(get_speed_lerp(), 0.3)
			
			var divespeed_coefficient = 1
			if (desired_dir.normalized().y > 0):
				divespeed_coefficient = 1 + desired_dir.normalized().y * 10
			
			velocity = velocity.lerp(desired_dir * velocity.length(), divespeed_coefficient * speed_weight * 0.05 * 60 * delta)
			
			#var dot_weight = velocity.normalized().dot(desired_dir.normalized())
			check_flap()
			
	# water bird
		PlayerStates.DIVE:
			set_wing_amt(0.0)
			
			# Thoughts:
			# Copy air code, high degree of friction
			# ... (vel * 0.9 or smth every frame modified by delta)
			# When facing up or dropping below a speed or above a certain timer, go back up
			# Have a max speed otw back up
			
			# this math is kinda temp still but i like the vibe of it.
			# basically the longer you stay pointed down the longer you go
			# tthink about it like variable height jump from mario
			var pitch = pitch_pivot.global_transform.basis.z.normalized().y # -1 is straight up, 1 is straight down
			if pitch < 0 or is_bird_surfacing: # facing up
				# have a stronger force once the apex of the dive is reached
				is_bird_surfacing = true
				velocity.y += pow(-position.y, 1.6) / 100 + 0.5
				#clampf(velocity.y, 0, 50)
			
			else:
				velocity.y += pow(-position.y, 1.4) / 150 * (6-pow(pitch+2, 1.4))
				#clampf(velocity.y, 0, 50)
		
		
	move_and_slide()

func check_flap() -> void:
	if Input.is_action_just_pressed("Flap"):
		flap_time = FLAP_DUR
		var playback = model.get_anim_tree().get(air_state_playback_path) as AnimationNodeStateMachinePlayback
		playback.travel(FLAP_STATE_NAME)

func set_shader_value(param: String, value):
	$UnderwaterEffect.get_child(0).material.set_shader_parameter(param, value);

func camera_enter_water():
	camera_in_water = true
	
	var tween = get_tree().create_tween()
	tween.set_ease(tween.EASE_IN) # idk if this does anything
	
	tween.tween_method(func(value): set_shader_value("activate", value), 0.0, 1.0, 0.1); # args are: (method to call / start value / end value / duration of animation)
	
	## TODO add sound adjustments

func camera_exit_water():
	camera_in_water = false
	
	var tween = get_tree().create_tween()
	tween.set_ease(tween.EASE_IN)
	tween.tween_method(func(value): set_shader_value("activate", value), 1.0, 0.0, 0.1); # args are: (method to call / start value / end value / duration of animation)
	
	## TODO add any sound adjustments
