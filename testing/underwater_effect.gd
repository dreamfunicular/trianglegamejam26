extends CanvasLayer

var in_water :bool = false

func set_shader_value(param: String, value):
	$Shader.material.set_shader_parameter(param, value);


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
	
func _process(_delta) -> void:
	if (Input.is_action_just_released("ui_accept")): # this is super super temporary just for testing, this whole class can be something else
		if not in_water:
			enter_water()
			
		else:
			exit_water()
	
