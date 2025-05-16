extends HBoxContainer

@onready var label: Label = $Label
@onready var button: Button = $Button

var is_held := false
var drag_speed_multiplier = 32.0
var prev_distance := 0.0
#var is_moving_mouse := false

func _on_button_button_down() -> void:
	is_held = true

func _on_button_button_up() -> void:
	is_held = false

func _process(delta: float) -> void:
	if is_held and InputEventMouseMotion:
		var mouse_pos := get_global_mouse_position()
		var button_middle_xpos := button.position.x + (button.size.x / 2.0)
		var button_to_mouse_distance : float = abs(button_middle_xpos - mouse_pos.x)
		if button_to_mouse_distance != prev_distance:
			print("dist: %.2f" % button_to_mouse_distance)
			prev_distance = button_to_mouse_distance
		#if not button.get_rect().has_point(mouse_pos):
		if button_to_mouse_distance > 30.0:
			drag_speed_multiplier = 32.0
		else:
			drag_speed_multiplier = 2.0
		if button_to_mouse_distance > 4.0: # not exactly on spot
			if mouse_pos.x > button_middle_xpos:
				label.custom_minimum_size.x += delta * 60 * drag_speed_multiplier
			else:
				label.custom_minimum_size.x -= delta * 60 * drag_speed_multiplier
		else:
			if button_to_mouse_distance != 0.0:
				#mouse_pos.x = (2 * mouse_pos.x) - button_middle_xpos
				mouse_pos.x += mouse_pos.x - button_middle_xpos

#func _gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion:
	#else:
		#
