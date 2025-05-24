@tool
extends ConfirmationDialog
var ok_btn : Button

signal new_pwl_saved

const NEW_PWL_SAVE_PATH := "res://project_wide_lisence.tres"

@onready var owner_pn_d: HBoxContainer = %OwnerPnD
@onready var license_pn_o: HBoxContainer = %LicensePnO


func _ready() -> void:
	hide()
	ok_btn = get_ok_button()
	ok_btn.disabled = true


func _on_param_and_data_text_changed(new_text : String) -> void:
	ok_btn.disabled = new_text.is_empty()


func _on_confirmed() -> void:
	print("yogurt | %s | %s" % [
		owner_pn_d.get_value(),
		license_pn_o.get_value()
	])
	var new_pwl = ALZProjectWideLicense.new(
		owner_pn_d.get_value(),
		license_pn_o.get_value()
	)
	ResourceSaver.save(new_pwl, NEW_PWL_SAVE_PATH)
	new_pwl_saved.emit()


func is_pwl_exist():
	return FileAccess.file_exists(NEW_PWL_SAVE_PATH)
