@tool
extends HBoxContainer

func fill_row(path_license_data : Dictionary):
	$AddonName.text = path_license_data["name"]
	$LicenseName.text = path_license_data["license"]
