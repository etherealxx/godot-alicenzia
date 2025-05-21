@tool
class_name AssetDataRow extends AbstractDataRow

const DOT := "."

signal expand_button(index : int, expand_yes : bool)
signal open_data(data : JSON)

@onready var asset_name: Button = $AssetName
@onready var asset_type: OptionButton = $AssetType
@onready var asset_extension: Button = $AssetExtension
@onready var asset_ownership_type: OptionButton = $AssetOwnType
@onready var asset_creator: OptionButton = $AssetCreator
@onready var asset_license: OptionButton = $AssetLicense
@onready var asset_usage: LineEdit = $AssetUsage
@onready var asset_mods: LineEdit = $AssetMods
@onready var asset_link: LineEdit = $AssetLink
@onready var asset_path: LineEdit = $AssetPath
@onready var view_full_lisence_btn: Button = $ViewFullLisenceBtn


func _ready() -> void:
	for idx : int in cell_path_cache.size():
		var cell : Control = get_node(cell_path_cache[idx])
		
		reset_length(cell)
				
		if "index_meta_name" in cell:
			cell.index_meta_name = INDEX_META_NAME
		cell.set_meta(INDEX_META_NAME, idx)
		if cell.has_signal("expand_button"):
			cell.expand_button.connect(
				func(idx, expand_yes): expand_button.emit(idx, expand_yes)
				)
	
	
func fill_data(file_path : String):
	var file_name := file_path.get_file()
	asset_name.text = file_name
	
	var extension := ""
	if DOT in file_name:
		if file_name.get_slice_count(DOT) > 1:
			if not file_name.get_slice(DOT, 0).is_empty():
				extension = file_name.get_slice(
								DOT,
								file_name.get_slice_count(DOT) - 1).to_lower()
	asset_extension.text = extension
	
	asset_path.text = file_path


func toggle_expand_button(target_idx : int, is_currently_expanding : bool) -> float: # and return new length
	var btn_to_expand : Button = _get_cell_from_cache(target_idx)
	btn_to_expand.text_overrun_behavior = \
		TextServer.OVERRUN_TRIM_ELLIPSIS if is_currently_expanding else TextServer.OVERRUN_NO_TRIMMING
	btn_to_expand.is_currently_expanding = not is_currently_expanding
	
	# shrink other buttons
	for idx : int in cell_path_cache.size():
		if idx == target_idx:
			continue
		var cell : Control = get_node(cell_path_cache[idx])
		if "is_currently_expanding" in cell:
			cell.is_currently_expanding = false
			cell.text_overrun_behavior = \
				TextServer.OVERRUN_TRIM_ELLIPSIS

	return btn_to_expand.get_combined_minimum_size().x


func get_min_length_references() -> PackedFloat32Array:
	var ref := PackedFloat32Array()
	for cellpath in cell_path_cache:
		var cell : Control = get_node(cellpath)
		var ref_length : float = maxf(cell.get_combined_minimum_size().x, cell.size.x)
		ref.append(ref_length)
	return ref
	

func pack_data_into_dict() -> Dictionary:
	var asset_data_dict : Dictionary[String, String] = {
		"asset_name" = asset_name.text,
		"asset_path" = asset_path.text
	}
	return asset_data_dict


func _on_row_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		open_data.emit(pack_data_into_dict())
