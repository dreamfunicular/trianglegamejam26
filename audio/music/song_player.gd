extends Node2D


func _ready():
	$"Above Water".play()
	$"Below Water".play()
	
	exit_water()


func enter_water():
	var tween = create_tween()
	tween.tween_property($"Below Water", "volume_db", -12.0, 0.2).set_trans(Tween.TRANS_EXPO)
	
	var bus_index := AudioServer.get_bus_index("MainMusic")
	var effect: AudioEffectFilter = AudioServer.get_bus_effect(bus_index, 0)

	var tween2 := create_tween()
	tween2.tween_property(effect, "cutoff_hz", 500.0, 0.2)
		#.from_current()\
		#.set_ease(Tween.EASE_OUT)\
		#.set_trans(Tween.TRANS_LINEAR)


func exit_water():
	var tween = create_tween()
	tween.tween_property($"Below Water", "volume_db", -80.0, 0.1)
	
	var bus_index := AudioServer.get_bus_index("MainMusic")
	var effect: AudioEffectFilter = AudioServer.get_bus_effect(bus_index, 0)

	var tween2 := create_tween()
	tween2.tween_property(effect, "cutoff_hz", 20500.0, 0.1)
		#.from_current()\
		#.set_ease(Tween.EASE_OUT)\
		#.set_trans(Tween.TRANS_LINEAR)


	
