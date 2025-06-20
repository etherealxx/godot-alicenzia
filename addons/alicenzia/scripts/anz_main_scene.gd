@tool
extends VBoxContainer

signal addon_refresh # addon
#signal data_button_expand_request(idx : int, expand_yes : bool)

#const ASSET_DATA_ROW : PackedScene = preload("uid://dagdcisuqdljk")

@export var prepare_data_rows_on_start := true

@onready var file_digger: Node = $RecursiveFileDigger
@onready var assets_table: VBoxContainer = %AssetsTable
@onready var expanded_box: VBoxContainer = %ExpandedBox


func _ready() -> void:
	if not Engine.is_editor_hint():
		_addon_init()
		expanded_box._ready()


func _addon_init():
	#data_button_expand_request.connect(_on_data_button_expand_request)
	assets_table.clear_row()
	if prepare_data_rows_on_start:
		var path_data : PackedStringArray = file_digger.start_walk_dir("res://")
		#print(path_data)
		for path : String in path_data:
			assets_table.add_data_row(path)
			#	func(idx, expand_yes): data_button_expand_request.emit(idx, expand_yes))


func _on_refresh_addon_btn_pressed() -> void:
	print("---")
	addon_refresh.emit()


func _on_refresh_table_btn_pressed() -> void:
	#%AssetsTable.refresh()
	pass
