@tool
extends VBoxContainer

signal addon_refresh # addon
#signal data_button_expand_request(idx : int, expand_yes : bool)

#const ASSET_DATA_ROW : PackedScene = preload("uid://dagdcisuqdljk")

const RES_PATH := "res://"

@export var prepare_data_rows_on_start := true

@onready var file_digger: Node = $RecursiveFileDigger
@onready var assets_table: VBoxContainer = %AssetsTable
@onready var expanded_box: VBoxContainer = %ExpandedBox
@onready var scan_license_dialog: ConfirmationDialog = %ScanLicenseDialog
@onready var scan_result_dialog: ConfirmationDialog = %ScanResultDialog
@onready var full_license_text_area: TextEdit = %FullLicenseTextArea
@onready var full_license_dialog: AcceptDialog = %FullLicenseDialog


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


func on_refresh_license_table(vbox : VBoxContainer): # called from main script
	#print(vbox.is_inside_tree())
	var table_parent := assets_table.get_parent()
	assets_table.queue_free()
	#vbox.get_parent().remove_child(vbox)
	table_parent.add_child(vbox)


func _on_scan_license_btn_pressed() -> void:
	scan_license_dialog.show_and_update()


func _on_scan_license_dialog_confirmed() -> void:
	print("begin scan!")
	var path_license_data_array : Array = scan_license_dialog.begin_scan()
	var license_rows : Array[Control] = scan_result_dialog.build_rows(path_license_data_array)
	for row in license_rows:
		row.show_license.connect(_on_scanned_license_row_full_lic_pressed)
	
	scan_result_dialog.show()


func _on_scanned_license_row_full_lic_pressed(thisrow_license_data):
	#var data : Dictionary = scan_result_row.thisrow_license_data
	var license_respath = thisrow_license_data["license_path"]
	print(license_respath)
	full_license_text_area.text = ""
	full_license_dialog.title = ""
	var dir = DirAccess.open(RES_PATH)
	if dir.file_exists(license_respath):
		var license_text := FileAccess.get_file_as_string(license_respath)
		full_license_text_area.text = license_text
		full_license_dialog.title = thisrow_license_data["name"]
		full_license_dialog.show()
