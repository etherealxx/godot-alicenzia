@tool
extends Resource
class_name ALZProjectLicenseDatabase

@export var project_wide_license : ALZProjectWideLicense

@export var path_license_dict : Dictionary[String, PathLicenseData]
