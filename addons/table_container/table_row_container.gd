@tool
class_name TableRowContainer extends HBoxContainer

signal draggable_buttons_setup_finished

const DEFAULT_STYLEBOX_UID := "uid://mo4xftcfdd0g"

enum RowOrder {FIRST, LAST, ONLY}

@export_tool_button("Setup Draggable Buttons", "Callable") var setup_action = setup_draggable_buttons
@export_tool_button("Clear Buttons", "Callable") var clearbtn_action = clear_drag_buttons
@export var resizable_cells := true
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var minimum_cell_length : float = 0.0
@export_custom(PROPERTY_HINT_NONE, "suffix:nodes", 6 | PROPERTY_USAGE_READ_ONLY) var current_buttons_amount := 0
@export_custom(PROPERTY_HINT_NONE, "suffix:nodes", 6 | PROPERTY_USAGE_READ_ONLY) var is_reference_row := false

var is_draggable_button_set := false

func _ready() -> void:
	var parent = get_parent()
	if parent:
		if ("minimum_cell_length" in parent) and (minimum_cell_length == 0.0):
			minimum_cell_length = parent.minimum_cell_length
	if resizable_cells and not Engine.is_editor_hint():
		await setup_draggable_buttons()
		draggable_buttons_setup_finished.emit()
		is_draggable_button_set = true
		#print(get_draggable_buttons())

func queue_execute_after_buttons_set(method : Callable):
	if not is_draggable_button_set:
		await draggable_buttons_setup_finished
	method.call()

func setup_dragbtn_style(row_order : RowOrder):
	var btnstyle : StyleBoxFlat = ResourceLoader.load(DEFAULT_STYLEBOX_UID, "StyleBoxFlat").duplicate()
	match (row_order):
		RowOrder.FIRST:
			btnstyle.expand_margin_top = 0
		RowOrder.LAST:
			btnstyle.expand_margin_bottom = 0
		RowOrder.ONLY:
			btnstyle.expand_margin_top = 0
			btnstyle.expand_margin_bottom = 0
	for dragbtn : TableRowDragButton in get_draggable_buttons():
		dragbtn.set_theme_pack(btnstyle)
 
func unset_reference():
	is_reference_row = false

func get_draggable_buttons() -> Array[TableRowDragButton]:
	var arr : Array[TableRowDragButton]
	get_children().filter(func(child): if child is TableRowDragButton: arr.append(child))
	return arr

func set_as_reference_row():
	if not is_reference_row:
		var parent = get_parent()
		if parent:
			parent.get_children().filter(func(child): if child is TableRowContainer: child.unset_reference())
		is_reference_row = true

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
