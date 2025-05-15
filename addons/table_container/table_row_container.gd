@tool
class_name TableRowContainer extends HBoxContainer

#const TABLE_ROW_DRAG_BUTTON = preload("uid://bxw4naupdywpp")

@export_tool_button("Setup Draggable Buttons", "Callable") var setup_action = setup_draggable_buttons
@export_tool_button("Clear Buttons", "Callable") var clearbtn_action = clear_drag_buttons
@export var resizable_cells := true
@export_custom(PROPERTY_HINT_NONE, "suffix:nodes", 6 | PROPERTY_USAGE_READ_ONLY) var current_buttons_amount := 0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var minimum_cell_length : float = 0.0

func _ready() -> void:
	var parent = get_parent()
	if ("minimum_cell_length" in parent) and (minimum_cell_length == 0.0):
		minimum_cell_length = parent.minimum_cell_length
	if resizable_cells and not Engine.is_editor_hint():
		setup_draggable_buttons()

func clear_drag_buttons():
	# clear all previous dragbtn
	get_children().filter(func(child): if child is TableRowDragButton: child.queue_free())
	current_buttons_amount = 0

func setup_draggable_buttons():
	clear_drag_buttons()
	await get_tree().create_timer(0.2, true, true).timeout # clear delay
	
	var filtered_childs := get_children().filter(func(child): return child is not TableRowDragButton)
	for index : int in filtered_childs.size():
		if index == 0: continue
		var child : Node = filtered_childs.get(index)
		var one_index_behind := child.get_index() - 1
		if get_child(one_index_behind) is not TableRowDragButton:
			var new_dragbtn := TableRowDragButton.new()
			#var new_dragbtn := TABLE_ROW_DRAG_BUTTON.instantiate()
			var prev_child : Node = filtered_childs.get(index - 1)
			
			#add_child(new_dragbtn, false)
			#move_child(new_dragbtn, prev_child.get_index() + 1)
			prev_child.add_sibling(new_dragbtn)
			
			new_dragbtn.owner = get_tree().edited_scene_root
			new_dragbtn.set_control_to_adjust_node(prev_child)
			new_dragbtn.minimum_cell_length = minimum_cell_length
			#move_child(new_dragbtn, child.get_index())
	var dragbtn_count := 0
	for child in get_children():
		if child is TableRowDragButton: dragbtn_count += 1
	current_buttons_amount = dragbtn_count
