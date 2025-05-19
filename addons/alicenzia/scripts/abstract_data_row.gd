@tool
class_name AbstractDataRow extends HBoxContainer

const INDEX_META_NAME := "asset_data_row_idx"

@export var cell_path_cache : Array[NodePath]
@export var cell_minimum_length := 100.0
@export var custom_minimum_length : Dictionary[NodePath, float]


func reset_cells_length():
	for cellpath : NodePath in cell_path_cache:
		reset_length(get_node(cellpath))


func reset_length(cell : Control) -> float: # and return the chosen length
	var chosen_length : float
	var path_to_cell := self.get_path_to(cell)
	for cellpath : NodePath in custom_minimum_length.keys():
		if cellpath == path_to_cell:
			chosen_length = custom_minimum_length[cellpath]
			cell.custom_minimum_size.x = chosen_length
			return chosen_length
	chosen_length = cell_minimum_length
	cell.custom_minimum_size.x = chosen_length
	return chosen_length


func _get_cell_from_cache(target_idx : int) -> Control:
	for idx : int in cell_path_cache.size():
		if idx == target_idx:
			return get_node(cell_path_cache[idx])
	return null


func set_cell_new_minsize(idx : int, new_length : float) -> float: # and return chosen length
	var cell : Control = get_node(cell_path_cache[idx])
	var chosen_length := new_length
	if new_length == -1.0:
		chosen_length = reset_length(cell)
		return chosen_length
	cell.custom_minimum_size.x = chosen_length # - cell.get_combined_minimum_size().x
	return chosen_length


func adjust_min_length_with_ref(length_ref : PackedFloat32Array):
	for idx : int in length_ref.size():
		var cell : Control = get_node(cell_path_cache[idx])
		if length_ref[idx] > cell.custom_minimum_size.x:
			cell.custom_minimum_size.x = length_ref[idx]
