extends VBoxContainer

var score : int = 0
var display_score : int = 0

func _process(delta: float) -> void:
	@warning_ignore("narrowing_conversion")
	display_score = move_toward(display_score, score, int(60 * delta * 3))
	
	$Display.text = "%4d" % display_score
