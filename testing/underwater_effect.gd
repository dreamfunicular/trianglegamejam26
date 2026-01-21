extends CanvasLayer


func set_shader_value(param: String, value):
	# in my case i'm tweening a shader on a texture rect, but you can use anything with a material on it
	#var value = $Shader.material.get_shader_parameter(param)
	$Shader.material.set_shader_parameter(param, value);


func enter_water():
	var tween = get_tree().create_tween()
	tween.set_ease(tween.EASE_IN)
	
	#start_val = $Shader.material.get_shader_parameter(param)
	tween.tween_method(func(value): set_shader_value("activate", value), 0.1, 1.0, 0.1); # args are: (method to call / start value / end value / duration of animation)

	
	
func _process(float) -> void:
	pass
	if (Input.is_action_just_released("ui_accept")):
		enter_water()
	
