@tool
class_name TableRowDragButton extends Button

const DEFAULT_STYLEBOX_UID := "uid://mo4xftcfdd0g"

@export_storage var control_to_adjust_path : NodePath
@export_storage var sibling_to_hold : Control

var control_to_adjust : Control
var is_held := false
var drag_speed_multiplier = 32.0
var prev_distance := 0.0
var stable_x : float
var minimum_cell_length := 0.0

func _ready() -> void:
	set_theme_pack(ResourceLoader.load(DEFAULT_STYLEBOX_UID, "StyleBox"))
	mouse_default_cursor_shape = Control.CURSOR_HSIZE
	focus_mode = Control.FOCUS_NONE
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	if control_to_adjust_path:
		control_to_adjust = get_node(control_to_adjust_path)

func set_theme_pack(stylebox : StyleBox):
	set("theme_override_styles/normal", stylebox)

func set_control_to_adjust_node(control : Control):
	control_to_adjust_path = get_path_to(control)
	control_to_adjust = get_node(control_to_adjust_path)
	#print("control to adjust: %s" % control_to_adjust)
	#control_to_adjust.tree_exited.connect(_on_control_to_adjust_freed)

func _on_button_down() -> void:
	is_held = true
	var parent = get_parent()
	if parent is TableRowContainer:
		parent.set_as_reference_row()

func _on_button_up() -> void:
	is_held = false

func _process(delta: float) -> void:
	if is_held and InputEventMouseMotion:
		if control_to_adjust:
			var mouse_posx := get_global_mouse_position().x
			var button_middle_xpos := self.global_position.x + (self.size.x / 2.0)
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
					if control_to_adjust.custom_minimum_size.x > minimum_cell_length:
						control_to_adjust.custom_minimum_size.x -= delta * 60 * drag_speed_multiplier
			else:
				if button_to_mouse_distance != 0.0:
					#mouse_pos.x = (2 * mouse_pos.x) - button_middle_xpos
					mouse_posx += mouse_posx - button_middle_xpos
