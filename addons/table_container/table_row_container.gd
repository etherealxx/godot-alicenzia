@tool
class_name TableRowContainer extends HBoxContainer

signal draggable_buttons_setup_finished

const DEFAULT_STYLEBOX_UID := "uid://mo4xftcfdd0g"
const MIN_CELL_LENGTH_META_NAME := "_min_cell_length"

enum RowOrder {FIRST, LAST, ONLY}

@export_tool_button("Setup Draggable Buttons", "Callable") var setup_action = setup_draggable_buttons
@export_tool_button("Clear Buttons", "Callable") var clearbtn_action = clear_drag_buttons
@export var resizable_cells := true

#@export_group("Cell Length")
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var minimum_cell_length : float = 0.0
#@export var column_cell_length : Dictionary[int, float]
#@export var min_cell_length_exception : Dictionary[NodePath, float]

@export_group("Statistics")
@export_custom(PROPERTY_HINT_NONE, "suffix:nodes", 6 | PROPERTY_USAGE_READ_ONLY) var current_buttons_amount := 0
@export_custom(PROPERTY_HINT_NONE, "suffix:nodes", 6 | PROPERTY_USAGE_READ_ONLY) var is_reference_row := false

var is_draggable_button_set := false
var cell_dragbtn_pair_cache : Dictionary[NodePath, NodePath]

func _ready() -> void:
	var parent = get_parent()
	if parent:
		if ("minimum_cell_length" in parent) and (minimum_cell_length == 0.0):
			minimum_cell_length = parent.minimum_cell_length
	#if min_cell_length_exception:
		#_set_min_cell_length_metas()
	if resizable_cells and not Engine.is_editor_hint():
		await setup_draggable_buttons()
		draggable_buttons_setup_finished.emit()
		is_draggable_button_set = true
		#print(get_draggable_buttons())


### Helper methods ### ---

## Get chidren of this node, excluding the buttons.
func row_get_children() -> Array[Node]:
	var arr : Array[Node]
	get_children().filter(func(child): 
		if child is not TableRowDragButton: arr.append(child))
	return arr


## Get the nth child/cell of this node, excluding the buttons. 
## Visually, it starts from left to right.
func row_get_child(idx : int) -> Node:
	print("child: %s" % row_get_children().get(idx))
	return row_get_children().get(idx)


## Get the TableRowDragButton paired with the nth child/cell of this node, excluding the buttons.
func get_dragbtn_of_child(idx : int) -> TableRowDragButton:
	var child = row_get_child(idx)
	for dragbtn : TableRowDragButton in _get_draggable_buttons():
		if dragbtn.control_to_adjust == child:
			return dragbtn
	return null

## Return the index of the input node, if it was the child of this node. 
## Otherwise returns -1.
func cell_get_index(node : Node) -> int:
	var childs := row_get_children()
	for idx : int in childs.size():
		var cell := childs[idx]
		if cell == node:
			return idx
	push_error("Node not found. Returning -1")
	return -1


## Get the text of the nth child/cell of this node. 
## If the cell is a Control node that has "text" property. 
## Also handles special case of nodes like OptionButton.
func cell_get_text(idx : int) -> String:
	var child := row_get_child(idx)
	var cell_text := ""
	if "text" in child:
		cell_text = child.text
	elif child is OptionButton:
		cell_text = child.get_item_text(child.get_selected_id())
	return cell_text

### ---

#func _set_min_cell_length_metas():
	#for child_path : NodePath in min_cell_length_exception.keys():
		#if has_node(child_path):
			#var node := get_node(child_path)
			#if not self.is_ancestor_of(node):
				#continue
			#node.set_meta(MIN_CELL_LENGTH_META_NAME, min_cell_length_exception[child_path])


func _wait_until_buttons_set():
	if not is_draggable_button_set:
		await draggable_buttons_setup_finished


func _dragbtn_update_min_cell_length(column_cell_length : Dictionary[int, float]):
	var childs_arr := row_get_children()
	for idx : int in childs_arr.size():
		if idx in column_cell_length.keys():
			var child := childs_arr[idx]
			var dragbtn : TableRowDragButton = get_node(cell_dragbtn_pair_cache[self.get_path_to(child)])
			dragbtn.minimum_cell_length = column_cell_length[idx]


func queue_execute_after_buttons_set(method : Callable) -> Variant:
	await _wait_until_buttons_set()
	return method.call()


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
	for dragbtn : TableRowDragButton in _get_draggable_buttons():
		dragbtn.set_theme_pack(btnstyle)
 
func unset_reference():
	is_reference_row = false

func _get_draggable_buttons() -> Array[TableRowDragButton]:
	var arr : Array[TableRowDragButton]
	get_children().filter(func(child): 
		if child is TableRowDragButton: arr.append(child))
	return arr

func set_as_reference_row():
	if not is_reference_row:
		var parent = get_parent()
		if parent:
			parent.get_children().filter(func(child): 
				if child is TableRowContainer: child.unset_reference())
		is_reference_row = true

func clear_drag_buttons():
	# clear all previous dragbtn
	cell_dragbtn_pair_cache.clear()
	get_children().filter(func(child): 
		if child is TableRowDragButton: child.queue_free())
	current_buttons_amount = 0

func setup_draggable_buttons():
	clear_drag_buttons()
	await get_tree().create_timer(0.2, true, true).timeout # clear delay
	
	var filtered_childs := get_children().filter(func(child): 
		return child is not TableRowDragButton)
		
	for index : int in filtered_childs.size():
		if index == 0: continue
		var child : Node = filtered_childs.get(index)
		var one_index_behind := child.get_index() - 1
		if get_child(one_index_behind) is not TableRowDragButton:
			var new_dragbtn := TableRowDragButton.new()
			#var new_dragbtn := TABLE_ROW_DRAG_BUTTON.instantiate()
			
			var prev_child : Node = filtered_childs.get(index - 1) # will be the node paired with dragbtn
			
			#add_child(new_dragbtn, false)
			#move_child(new_dragbtn, prev_child.get_index() + 1)
			prev_child.add_sibling(new_dragbtn)
			
			new_dragbtn.owner = get_tree().edited_scene_root
			new_dragbtn.set_control_to_adjust_node(prev_child)
			cell_dragbtn_pair_cache[self.get_path_to(prev_child)] = self.get_path_to(new_dragbtn)
			new_dragbtn.minimum_cell_length = minimum_cell_length
			
			#@TODO remove if unnecessary
			if prev_child.has_meta(MIN_CELL_LENGTH_META_NAME):
				new_dragbtn.minimum_cell_length = prev_child.get_meta(
					MIN_CELL_LENGTH_META_NAME)

			#move_child(new_dragbtn, child.get_index())
	var dragbtn_count := 0
	for child in get_children():
		if child is TableRowDragButton: dragbtn_count += 1
	current_buttons_amount = dragbtn_count
