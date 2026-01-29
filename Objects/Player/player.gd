extends CharacterBody3D

const GRAV = -18.0

const CAMERA_ROLL_PERCENT = 0.5

const ROLL_SENSE = 0.8
const ROLL_NORMALIZE_SPEED = 4

const MOUSE_SENSE_FREE = Vector2(0.002, 0.004)
const TURN_CLAMP_FREE = Vector2(PI/72, PI/36)
const MOUSE_SENSE_WATER = Vector2(0.001, 0.001)
const TURN_CLAMP_WATER = Vector2(PI/108, PI/108)
const MOUSE_SENSE_FLOAT = Vector2(0.004, 0.004)
const TURN_CLAMP_FLOAT = Vector2(PI/18, PI/18)
var mouse_sense_vect = MOUSE_SENSE_FREE
var turn_clamp_vect = TURN_CLAMP_FREE

@onready var pitch_pivot = $PitchPivot
@onready var camera = $PitchPivot/Camera3D
@onready var model = $PitchPivot/Gannet2

# Camera settings (COME BACK TO THESE FOR SPEED STUFF)
const CAMERA_DISTANCE = 4.0
const CAMERA_HEIGHT = 1.2

var roll : float = 0.0
var barrel_roll: float = 0.0

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
const FLAP_COST = 6.0
const FLAP_POWER = 1.25
const FLAP_DUR = 1.75
const FLAP_COOLDOWN = 0.5
var flap_time = -FLAP_COOLDOWN

@onready var gui = get_tree().root.find_child("Gui", true, false)

@export var boost_blend: Curve
const BOOST_POWER = 1.8
const BOOST_BUF = 0.1
const NON_BOOST_TIME = 0.3
const BOOST_DUR = 2.0
var boost_time = 0.0
var boost_click = -NON_BOOST_TIME
var boost_click_2 = -NON_BOOST_TIME

const SHAKE_FREQUENCY : float = 0.2
var shake_mag : float = 0.0
var shake_target : float = 0.0
var shake_time : float = 0.0
var shake_dir : float = 0.0

var splash_scene = preload("res://Environment/SplashInstance.tscn")
var upward_splash_scene = preload("res://Environment/UpwardSplashInstance.tscn")

@onready var playback = model.get_anim_tree().get(air_state_playback_path) as AnimationNodeStateMachinePlayback

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	velocity = -transform.basis.z * 30.0

func _input(event) -> void:
	if event is InputEventMouseMotion:
		var weight = update_steer()
		var mouse_sense = lerp(mouse_sense_vect.y, mouse_sense_vect.x, weight)
		var turn_clamp = lerp(turn_clamp_vect.y, turn_clamp_vect.x, weight)
		var float_state = state != PlayerStates.FLOAT
		turn_camera(clamp(-event.relative.x * mouse_sense, -turn_clamp, turn_clamp),
			clamp(-event.relative.y * mouse_sense, -turn_clamp, turn_clamp), float_state)

func turn_camera(rad_x: float, rad_y: float, rolling: bool):
	rotate_y(rad_x)
	pitch_pivot.rotate_x(rad_y)
	if (rolling && abs(roll) < PI/4): roll = clamp(roll - (rad_x * ROLL_SENSE), -PI/4, PI/4)
	if rolling:
		model.rotation.x = 0.0
	else:
		model.rotation.x = -pitch_pivot.rotation.x

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
		
		PlayerStates.FLOAT:
			mouse_sense_vect = MOUSE_SENSE_FLOAT
			turn_clamp_vect = TURN_CLAMP_FLOAT
			return 0.000
	
	return 0.0

func set_shake(shake: float):
	if (shake > shake_target):
		shake_target = shake

func update_cam(delta: float):
	var weight = clamp((velocity.length() - 20.0) / 80.0, 0.0, 1.0)
	
	camera.fov = lerp(75.0, 125.0, weight)
	
	shake_time += delta
	shake_target = move_toward(shake_target, 0.0, 0.01 * 60 * delta)
	shake_mag = lerp(shake_mag, shake_target, 0.1 * 60 * delta)
	
	if (shake_time > SHAKE_FREQUENCY):
		shake_time = 0.0
		shake_dir += randf_range(0.6 * PI, 1.4 * PI)
		shake_dir = fposmod(shake_dir, TAU)
	
	var offset = sin(shake_time / SHAKE_FREQUENCY * PI) * shake_mag * Vector2.from_angle(shake_dir) * 0.3
	
	#camera.position = Vector3(offset.x, CAMERA_HEIGHT + offset.y, CAMERA_DISTANCE)
	camera.position = Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	camera.rotation.y = offset.x * PI / 9
	camera.rotation.x = offset.y * PI / 9
	
	if (camera.global_position.y < 0 && not camera_in_water):
		camera_enter_water()
	
	if (camera.global_position.y > 0 && camera_in_water):
		camera_exit_water()
	

func update_state():
	match state:
		PlayerStates.FLY:
			if position.y < 0:
				if (flap_time < 0.0 && velocity.y > -10.0 && velocity.length() < 30.0):
					state = PlayerStates.FLOAT
					velocity.y = 0
					playback.travel(FLOAT_STATE_NAME)
				else:
					state = PlayerStates.DIVE
					is_bird_surfacing = false
					entry_speed = velocity.length() * 0.9
					
					var _new_spash = splash_scene.instantiate()
					add_sibling(_new_spash)
					
					boost_click = -NON_BOOST_TIME
					
					playback.travel(DIVE_STATE_NAME)
					
		
		PlayerStates.DIVE:
			if position.y > 0:
				state = PlayerStates.FLY
				var _new_up_spash = upward_splash_scene.instantiate()
				add_sibling(_new_up_spash)
				
				if (boost_click > 0.0 && boost_click_2 == -NON_BOOST_TIME):
					boost_time = BOOST_DUR
					playback.travel(SUPER_STATE_NAME)
					set_shake(1.0)
					$"BirdSounds/Burst Hit Noise".play()
				else:
					playback.travel(FLIGHT_STATE_NAME)
		
		PlayerStates.FLOAT:
			if flap_time == FLAP_DUR:
				state = PlayerStates.FLY
				playback.travel(FLIGHT_STATE_NAME)

func get_speed_lerp() -> float:
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
	update_cam(delta)
	
	var wing_amt_height = clamp(position.y/2.0, 0.0, 1.0)
	var wing_amt_dive = clamp(1.2 - pitch_pivot.global_transform.basis.z.normalized().y * 1.4, 0.0, 1.0)
	var wing_amt_speed = clamp(1 - (velocity.length() - 40)/50, 0.0, 1.0) * 0.3 + 0.7
	set_wing_amt(wing_amt_height * wing_amt_dive * wing_amt_speed)
	#
	roll = lerp(roll, 0.0, 1.0 - exp(-ROLL_NORMALIZE_SPEED * delta))
	barrel_roll = lerp(barrel_roll, 0.0, 1.0 - exp(-ROLL_NORMALIZE_SPEED * delta))
	model.rotation.z = -roll - barrel_roll
	rotation.z = (-roll * CAMERA_ROLL_PERCENT)# - barrel_roll
	
	flap_time = decrement_counter(flap_time, FLAP_COOLDOWN, delta)
	boost_click = decrement_counter(boost_click, NON_BOOST_TIME, delta)
	boost_click_2 = decrement_counter(boost_click_2, NON_BOOST_TIME, delta)
	boost_time = decrement_counter(boost_time, 0, delta)
	
	# flying bird only code
	match state:
		PlayerStates.FLY:
			velocity.y += GRAV * delta
			
			var flight_dir = (-pitch_pivot.global_transform.basis.z + Vector3(0, abs(pitch_pivot.transform.basis.y.dot(Vector3.UP)), 0)).normalized()
			if (boost_time > 0):
				var percent_boost = boost_blend.sample(1 - boost_time/BOOST_DUR)
				velocity += percent_boost * flight_dir * BOOST_POWER * delta * 60
			else:
				if (flap_time > 0):
					var percent_flap = flap_blend.sample(1 - flap_time/FLAP_DUR)
					velocity += percent_flap * flight_dir * FLAP_POWER * delta * 60
					
				check_flap()
			var desired_dir = -pitch_pivot.global_transform.basis.z
			
			var speed_weight = pow(ease(get_speed_lerp(), 0.3), 1.4)
			var turn_weight = pow((1 - abs(velocity.normalized().dot(desired_dir.normalized()))), 1.3)
			
			#var pitch = pitch_pivot.rotation.x
			#if abs(pitch) > PI * 0.7:
				#barrel_roll -= PI
				#var temp = roll
				#turn_camera(PI, 2 * sign(pitch) * (PI/2 - abs(pitch)), true)
				#roll = temp
			
			steer_and_fric(0.045 * 60 * delta, speed_weight * turn_weight * 0.025 * 60 * delta)
			
	# water bird
		PlayerStates.DIVE:
			model.get_anim_tree().set(dive_blend_path, clamp(position.y/-10.0, 0.0, 1.0));
			
			var pitch = pitch_pivot.global_transform.basis.z.normalized().y # -1 is straight up, 1 is straight down
			if pitch < -0.1 or velocity.length() < 10.0 or is_bird_surfacing or velocity.y > 0: # facing up
				# have a stronger force once the apex of the dive is reached
				is_bird_surfacing = true
				velocity.y += (pow(-position.y, 1.6) / 150 + 0.5) * delta * 60
				if (velocity.length() > entry_speed): velocity = velocity.lerp(entry_speed * velocity.normalized(), delta * 60 * 0.5)
			
			else:
				velocity.y += (pow(-position.y, 1.2) / 100 + 0.5) * delta * 60
			
			var speed_weight = 1.0 - clamp(velocity.length() / 50, 0.2, 1.0)
			turn_camera(0.0, (1.0 - pitch) * clamp((-position.y) / 70, 0.5, 1.0) * 0.5 * (0.6 + 0.4 * int(is_bird_surfacing)) * delta, true)
			steer_and_fric(0.01 * 60 * delta, 0.01 * speed_weight * 60 * delta)
			
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
	if Input.is_action_just_pressed("Flap") && flap_time == -FLAP_COOLDOWN && gui.use_stamina(FLAP_COST):
		flap_time = FLAP_DUR
		playback.travel(FLAP_STATE_NAME)
		
		# and play a sound
		var num = randi_range(0, 4) 
		$BirdSounds/Flap.get_child(num).play()
		
		set_shake(0.4)

func set_shader_value(param: String, value):
	$UnderwaterEffect.get_child(0).material.set_shader_parameter(param, value);

func camera_enter_water():
	camera_in_water = true
	
	var tween = get_tree().create_tween()
	tween.set_ease(tween.EASE_IN) # idk if this does anything
	
	tween.tween_method(func(value): set_shader_value("activate", value), 0.0, 1.0, 0.1); # args are: (method to call / start value / end value / duration of animation)
	
	## TODO add sound adjustments
	SongPlayer.enter_water()

func camera_exit_water():
	camera_in_water = false
	
	var tween = get_tree().create_tween()
	tween.set_ease(tween.EASE_IN)
	tween.tween_method(func(value): set_shader_value("activate", value), 1.0, 0.0, 0.1); # args are: (method to call / start value / end value / duration of animation)
	
	## TODO add any sound adjustments
	SongPlayer.exit_water()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("get_id"):
		var id = body.get_id()
		gui.get_fish(id)
		body.die()
