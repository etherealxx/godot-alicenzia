@tool
extends ConfirmationDialog

const SCAN_RESULT_ROW = preload("res://addons/alicenzia/scenes/scan_result_row.tscn")
const WINDOW_MIN_Y := 80

@onready var row_list: VBoxContainer = $RowList
@onready var first_row: HBoxContainer = %FirstRow

func build_rows(path_license_data_array : Array[Dictionary]):
	for row in row_list.get_children():
		if row != first_row:
			row.queue_free()
			
	
	row_list.size.y = WINDOW_MIN_Y
	self.size.y = WINDOW_MIN_Y
	
	for path_license_data in path_license_data_array:
		var new_row := SCAN_RESULT_ROW.instantiate()
		row_list.add_child(new_row)
		new_row.fill_row(path_license_data)
