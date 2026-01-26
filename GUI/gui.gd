extends CanvasLayer

#const fish_amounts = [15, 35, 60, 100, 150, 250]
const fish_amounts = [15, 35, 60, 100, 150, 1]

@onready var fish_icon = preload("res://GUI/Fish Icons/FishIcon.tscn")

var timer = 0.0
var playing = true

func _process(delta: float) -> void:
	timer += delta
	$MarginContainer/Timer.text = str(floor(timer))
	
	if !playing && timer > 60:
		$MarginContainer/Timer.visible = false
		$"MarginContainer/Game Over".visible = true
		playing = false

func use_stamina(amount: float) -> bool:
	return $MarginContainer/Stamina.use_stamina(amount)

func get_fish(id: int) -> void:
	if playing:
		$MarginContainer/Score.change_score(fish_amounts[id])
		var new_icon = fish_icon.instantiate()
		new_icon.type = id
		add_child(new_icon)
		
		var viewport_size = get_viewport().get_visible_rect().size
		new_icon.position = Vector2(128, viewport_size.y - 48)
