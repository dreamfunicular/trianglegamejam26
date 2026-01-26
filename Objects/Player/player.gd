extends CharacterBody3D

const GRAV = -15.0

const CAMERA_ROLL_PERCENT = 0.5

const ROLL_SENSE = 0.8
const ROLL_NORMALIZE_SPEED = 4

const MOUSE_SENSE_FREE = Vector2(0.002, 0.004)
const TURN_CLAMP_FREE = Vector2(PI/72, PI/36)
const MOUSE_SENSE_WATER = Vector2(0.001, 0.001)
const TURN_CLAMP_WATER = Vector2(PI/108, PI/108)
var mouse_sense_vect = MOUSE_SENSE_FREE
var turn_clamp_vect = TURN_CLAMP_FREE

@onready var pitch_pivot = $PitchPivot
@onready var camera = $PitchPivot/Camera3D
@onready var model = $PitchPivot/Gannet2

# Camera settings (COME BACK TO THESE FOR SPEED STUFF)
const CAMERA_DISTANCE = 5.0
const CAMERA_HEIGHT = 2.0

var roll : float = 0.0

@export var flight_blend_path: String
@export var dive_blend_path: String
@export var air_state_playback_path: String
const FLIGHT_STATE_NAME : String = "Flight"
const SUPER_STATE_NAME : String = "SuperFlap"
const FLAP_STATE_NAME : String = "Flap"
const DIVE_STATE_NAME : String = "Dive"
const FLOAT_STATE_NAME : String = "Float"

var is_bird_surfacing : bool = false
var camera_in_water : bool = false
var entry_speed : float = 0.0

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

@export var boost_blend: Curve
const BOOST_POWER = 2.0
const BOOST_BUF = 0.1
const NON_BOOST_TIME = 0.5
const BOOST_DUR = 2.0
var boost_time = 0.0
var boost_click = -NON_BOOST_TIME
var boost_click_2 = -NON_BOOST_TIME

var splash_scene = preload("res://Environment/SplashInstance.tscn")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.position = Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	
	velocity = -transform.basis.z * 50.0

func _input(event) -> void:
	if event is InputEventMouseMotion:
		var weight = update_steer()
		var mouse_sense = lerp(mouse_sense_vect.y, mouse_sense_vect.x, weight)
		var turn_clamp = lerp(turn_clamp_vect.y, turn_clamp_vect.x, weight)
		#rotate_y(clamp(-event.relative.x * mouse_sense, -turn_clamp, turn_clamp))
		#pitch_pivot.rotate_x(clamp(-event.relative.y * mouse_sense, -turn_clamp, turn_clamp))
		#roll += event.relative.x * ROLL_SENSE
		turn_camera(clamp(-event.relative.x * mouse_sense, -turn_clamp, turn_clamp),
			clamp(-event.relative.y * mouse_sense, -turn_clamp, turn_clamp))

func turn_camera(rad_x: float, rad_y: float):
	rotate_y(rad_x)
	pitch_pivot.rotate_x(rad_y)
	roll += -rad_x * ROLL_SENSE

# the vectors it sets store the high and low values of mouse sense and max steer
# these values are set based on the player's state
# then based on whatever blending function is used to lerp between them, return that weight
# this function is only to be used in the _input function
func update_steer() -> float:
	match state:
		PlayerStates.FLY:
			mouse_sense_vect = MOUSE_SENSE_FREE
			turn_clamp_vect = TURN_CLAMP_FREE
			return get_speed_lerp()
			
		PlayerStates.DIVE:
			mouse_sense_vect = MOUSE_SENSE_WATER
			turn_clamp_vect = TURN_CLAMP_WATER
			return 0.000
	
	return 0.0

func update_cam():
	if (camera.global_position.y < 0 && not camera_in_water):
		camera_enter_water()
	
	if (camera.global_position.y > 0 && camera_in_water):
		camera_exit_water()

func update_state():
	var playback = model.get_anim_tree().get(air_state_playback_path) as AnimationNodeStateMachinePlayback
	match state:
		PlayerStates.FLY:
			if position.y < 0:
				if (flap_time < 0.0 && velocity.y > -10.0 && velocity.length() < 30.0):
					state = PlayerStates.FLOAT
					velocity.y = 0
					playback.travel(FLOAT_STATE_NAME)
					print("back")
				else:
					state = PlayerStates.DIVE
					is_bird_surfacing = false
					entry_speed = velocity.length() * 0.9
					
					var _new_spash = splash_scene.instantiate()
					add_sibling(_new_spash)
					
					boost_click = -NON_BOOST_TIME
					
					playback.travel(DIVE_STATE_NAME)
					
					## TODO: Add Sound Effect
					## TODO: Add Particles
		
		PlayerStates.DIVE:
			if position.y > 0:
				state = PlayerStates.FLY
				
				if (boost_click > 0.0 && boost_click_2 == -NON_BOOST_TIME):
					boost_time = BOOST_DUR
					playback.travel(SUPER_STATE_NAME)
				else:
					playback.travel(FLIGHT_STATE_NAME)
		
		PlayerStates.FLOAT:
			if flap_time == FLAP_DUR:
				print("hello")
				state = PlayerStates.FLY
				playback.travel(FLIGHT_STATE_NAME)

func get_speed_lerp() -> float:
	#if velocity.length() > 50: print("maxed out " + str(randi_range(0, 9)))
	return min(1.0, velocity.length() / 50)

func set_wing_amt(wing_amount: float) -> void:
	model.get_anim_tree().set(flight_blend_path, wing_amount);

func decrement_counter(counter: float, amt: float, delta: float) -> float:
	var ans = counter
	if (ans > -amt):
		ans -= delta
		if (ans < -amt):
			ans = -amt
	return ans

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
	
	flap_time = decrement_counter(flap_time, FLAP_COOLDOWN, delta)
	boost_click = decrement_counter(boost_click, NON_BOOST_TIME, delta)
	boost_time = decrement_counter(boost_time, 0, delta)
	
	# flying bird only code
	match state:
		PlayerStates.FLY:
			velocity.y += GRAV * delta
			
			if (boost_time > 0):
				var percent_boost = boost_blend.sample(1 - boost_time/BOOST_DUR)
				velocity += percent_boost * (-transform.basis.z + pitch_pivot.transform.basis.y).normalized() * BOOST_POWER
				#velocity = pow(entry_speed, 1.3) * (-transform.basis.z).normalized()
			else:
				if (flap_time > 0):
					var percent_flap = flap_blend.sample(1 - flap_time/FLAP_DUR)
					velocity += percent_flap * (-transform.basis.z + pitch_pivot.transform.basis.y).normalized() * FLAP_POWER
				
				check_flap()
			#var desired_dir = -pitch_pivot.global_transform.basis.z
			
			#var speed_weight = clamp(20.0 / max(velocity.length(), 1.0), 0.05, 1.0) * 0.9
			var speed_weight = ease(get_speed_lerp(), 0.3)
			
			#var divespeed_coefficient = 1
			#if (desired_dir.normalized().y > 0):
				#divespeed_coefficient = 1 + desired_dir.normalized().y * 10
			
			#velocity = velocity.lerp(desired_dir * velocity.length(), divespeed_coefficient * speed_weight * 0.05 * 60 * delta)
			#velocity = velocity.slerp(desired_dir * velocity.length(), divespeed_coefficient * speed_weight * 0.05 * 60 * delta)
			
			#velocity = velocity.lerp(Vector3.ZERO, speed_weight * 0.001 * 60 * delta)
			#velocity = velocity.slerp(desired_dir * velocity.length(), 1.0 * 0.05 * 60 * delta)
			steer_and_fric(0.05 * 60 * delta, speed_weight * 0.001 * 60 * delta)
			
			#var dot_weight = velocity.normalized().dot(desired_dir.normalized())
			
	# water bird
		PlayerStates.DIVE:
			model.get_anim_tree().set(dive_blend_path, clamp(position.y/-10.0, 0.0, 1.0));
			
			# Thoughts:
			# Copy air code, high degree of friction
			# ... (vel * 0.9 or smth every frame modified by delta)
			# When facing up or dropping below a speed or above a certain timer, go back up
			# Have a max speed otw back up ---- clamp to entry speed * 0.9 or smth !!!!
			
			# this math is kinda temp still but i like the vibe of it.
			# basically the longer you stay pointed down the longer you go
			# tthink about it like variable height jump from mario
			
			var pitch = pitch_pivot.global_transform.basis.z.normalized().y # -1 is straight up, 1 is straight down
			if pitch < -0.1 or velocity.length() < 10.0 or is_bird_surfacing or velocity.y > 0: # facing up
				# have a stronger force once the apex of the dive is reached
				is_bird_surfacing = true
				velocity.y += pow(-position.y, 1.6) / 150 + 0.5
				if (velocity.length() > entry_speed): velocity = velocity.lerp(entry_speed * velocity.normalized(), delta * 60 * 0.5)
				#velocity.y += 20 * delta
				#clampf(velocity.y, 0, 50)
				#turn_camera(0.0, (pitch.angle_to(Vector3.UP) ** 2) * 0.15 * delta)
				#turn_camera(desired_dir.cross(Vector3.UP).dot(velocity) * delta, (desired_dir.y - velocity.normalized().y) * delta)
			
			else:
				velocity.y += pow(-position.y, 1.4) / 150 #* (6-pow(pitch+2, 1.4))
				#velocity.y += 10 * delta
				#clampf(velocity.y, 0, 50)
				#turn_camera(0.0, (pitch.angle_to(Vector3.UP) ** 2) * 0.1 * delta)
				#turn_camera(0.0, (1.0 - pitch) * 0.15 * delta)
			
			turn_camera(0.0, (1.0 - pitch) * clamp((-position.y) / 70, 0.5, 1.0) * 0.5 * (0.6 + 0.4 * int(is_bird_surfacing)) * delta)
			steer_and_fric(0.01 * 60 * delta, 0.003 * 60 * delta)
			
			if Input.is_action_just_pressed("Flap"):
				boost_click_2 = boost_click
				boost_click = BOOST_BUF
		
		PlayerStates.FLOAT:
			velocity = velocity.lerp(Vector3.ZERO, 60 * 0.05 * delta)
			
			check_flap()
		
	move_and_slide()

func steer_and_fric(steer_weight: float, fric_weight: float):
	var desired_dir = -pitch_pivot.global_transform.basis.z
	
	velocity = velocity.lerp(Vector3.ZERO, fric_weight)
	velocity = velocity.slerp(desired_dir * velocity.length(), steer_weight)

func check_flap() -> void:
	if Input.is_action_just_pressed("Flap") && flap_time == -FLAP_COOLDOWN:
		flap_time = FLAP_DUR
		var playback = model.get_anim_tree().get(air_state_playback_path) as AnimationNodeStateMachinePlayback
		playback.travel(FLAP_STATE_NAME)
		
		# and play a sound
		var num = randi_range(0, 4) 
		$BirdSounds/Flap.get_child(num).play()

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
