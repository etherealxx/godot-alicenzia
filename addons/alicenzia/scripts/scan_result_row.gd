@tool
extends HBoxContainer

signal show_license(scanned_license_data : String)

var is_row_selected := false
var thisrow_license_data : Dictionary
#var license_respath : String


func fill_row(scanned_license_data : Dictionary):
	thisrow_license_data = scanned_license_data
	
	$AddonName.text = thisrow_license_data["name"]
	$LicenseName.text = thisrow_license_data["license"]
	#license_respath = scanned_license_data["license_path"]
	
	var c_year : int = thisrow_license_data["copyright_year"]
	var c_owner : String = thisrow_license_data["copyright_owner"]
	if c_year:
		$LicenseYear.text = str(c_year)
	if c_owner:
		$LicenseOwner.text = c_owner


func _on_full_license_pressed() -> void:
	show_license.emit(thisrow_license_data)


func _on_row_check_box_toggled(toggled_on: bool) -> void:
	is_row_selected = toggled_on
