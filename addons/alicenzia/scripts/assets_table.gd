@tool
extends VBoxContainer

const ASSET_DATA_ROW : PackedScene = preload("uid://dagdcisuqdljk")

@export_tool_button("Clear Row", "Callable") var action_clear = clear_row

@onready var first_row: AbstractDataRow = $FirstRow


func _ready() -> void:
	var asset_data_row_ref := ASSET_DATA_ROW.instantiate()
	add_child(asset_data_row_ref)
	var length_ref : PackedFloat32Array = asset_data_row_ref.get_min_length_references()
	first_row.adjust_min_length_with_ref(length_ref)
	var cellpath_minlength_pair = first_row.pair_nodepath_with_minlength_from_ref(length_ref)
	first_row.adjust_special_case_with_pair(cellpath_minlength_pair)
	asset_data_row_ref.queue_free()


func clear_row():
	for child : Node in get_children():
		#if not child.is_in_group("first_row"):
		if child != first_row:
			child.queue_free()


func get_data_rows() -> Array[AssetDataRow]:
	var arr : Array[AssetDataRow]
	for child : Node in get_children():
		if child is AssetDataRow:
			arr.append(child)
	return arr


func add_data_row(data_path : String):
		var new_data_row := ASSET_DATA_ROW.instantiate()
		add_child(new_data_row)
		new_data_row.fill_data(data_path)
		new_data_row.expand_button.connect(_on_data_button_expand_request)

#@TODO check if the column who send request doesn't have an expandable
# button, like all of their size is small enough they need no expansion
func _on_data_button_expand_request(idx : int, is_currently_expanding : bool):
	var data_rows : Array[AssetDataRow] = get_data_rows()
	var lengthiest := 0.0
	
	for row : AssetDataRow in data_rows:
		var button_length : float = row.toggle_expand_button(idx, is_currently_expanding)
		lengthiest = maxf(button_length, lengthiest)
	
	var new_length := -1.0 if is_currently_expanding else lengthiest
	
	var final_length : float
	for row : AssetDataRow in data_rows:
		row.reset_cells_length()
		final_length = row.set_cell_new_minsize(idx, new_length)
	#print(final_length)
	first_row.reset_cells_length()
	first_row.set_cell_new_minsize(idx, final_length)
