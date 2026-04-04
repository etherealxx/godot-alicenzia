@tool
extends HBoxContainer

func fill_row(path_license_data : Dictionary):
	$AddonName.text = path_license_data["name"]
	$LicenseName.text = path_license_data["license"]
	
	var c_year : int = path_license_data["copyright_year"]
	var c_owner : String = path_license_data["copyright_owner"]
	if c_year:
		$LicenseYear.text = str(c_year)
	if c_owner:
		$LicenseOwner.text = c_owner
