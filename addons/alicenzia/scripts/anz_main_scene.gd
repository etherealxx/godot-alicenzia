@tool
extends VBoxContainer

signal addon_refresh # addon

const ASSET_DATA_ROW : PackedScene = preload("uid://dagdcisuqdljk")

@onready var file_digger: Node = $RecursiveFileDigger
@onready var assets_table: VBoxContainer = %AssetsTable


func _ready() -> void:
	if not Engine.is_editor_hint():
		_addon_init()


func _addon_init():
	await assets_table.clear_row()
	var path_data : PackedStringArray = file_digger.start_walk_dir("res://")
	#print(path_data)
	for path : String in path_data:
		var new_data_row := ASSET_DATA_ROW.instantiate()
		assets_table.add_child(new_data_row)
		new_data_row.fill_data(path)


func _on_refresh_addon_btn_pressed() -> void:
	print("---")
	addon_refresh.emit()


func _on_refresh_table_btn_pressed() -> void:
	#%AssetsTable.refresh()
	pass
