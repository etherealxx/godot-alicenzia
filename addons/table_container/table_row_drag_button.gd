@tool
class_name TableRowDragButton extends Button

@export_storage var control_to_adjust_path : NodePath
@export_storage var sibling_to_hold : Control

var control_to_adjust : Control
var is_held := false
var drag_speed_multiplier = 32.0
var prev_distance := 0.0
var stable_x : float

func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	if control_to_adjust_path:
		control_to_adjust = get_node(control_to_adjust_path)

func set_control_to_adjust_node(control : Control):
	control_to_adjust_path = get_path_to(control)
	control_to_adjust = get_node(control_to_adjust_path)
	#print("control to adjust: %s" % control_to_adjust)
	#control_to_adjust.tree_exited.connect(_on_control_to_adjust_freed)

func _on_button_down() -> void:
	is_held = true

func _on_button_up() -> void:
	is_held = false

func _process(delta: float) -> void:
	if is_held and InputEventMouseMotion:
		if control_to_adjust:
			var mouse_posx := get_global_mouse_position().x
			var button_middle_xpos := self.position.x + (self.size.x / 2.0)
			var button_to_mouse_distance : float = abs(button_middle_xpos - mouse_posx)
			if button_to_mouse_distance != prev_distance:
				prev_distance = button_to_mouse_distance
			#if not button.get_rect().has_point(mouse_pos):
			if button_to_mouse_distance > 20.0:
				drag_speed_multiplier = 32.0
			else:
				drag_speed_multiplier = 4.0
			if button_to_mouse_distance > 4.0: # not exactly on spot
				if mouse_posx > button_middle_xpos:
					control_to_adjust.custom_minimum_size.x += delta * 60 * drag_speed_multiplier
				else:
					control_to_adjust.custom_minimum_size.x -= delta * 60 * drag_speed_multiplier
			else:
				if button_to_mouse_distance != 0.0:
					#mouse_pos.x = (2 * mouse_pos.x) - button_middle_xpos
					mouse_posx += mouse_posx - button_middle_xpos
