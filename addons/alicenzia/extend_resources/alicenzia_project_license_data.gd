@tool
extends Resource
class_name ALZProjectLicenseDatabase

@export var project_name : String
@export var project_wide_license : ALZProjectWideLicense

@export var path_license_dict : Dictionary[String, PathLicenseData]

@export var saved_default_changes : Array[ALZResDefaultsChanges]

func get_saved_default_changes_or_null(res_global_name : String) -> ALZResDefaultsChanges:
	for refdefchange : ALZResDefaultsChanges in saved_default_changes:
		if refdefchange.res_script_globalname == res_global_name:
			return refdefchange
	return null
