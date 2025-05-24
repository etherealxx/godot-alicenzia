@tool
extends Resource
class_name PathLicenseData

enum AssetType {
	CODE, MUSIC
}

enum OwnershipType {
	INTERNALLY_MADE, EXTERNAL
}

enum Creator {
	Etherealxx
}

enum LicenseType {
	APACHE, MIT, CC_BY, CC0, CC_BY_SSA,
	CC_BY_NC_ND, GPLV3
}

@export_storage var asset_type_hint := "Code,Music"
@export_storage var ownership_type_hint := "Internally Made,External"
@export_storage var creator_hint := "Etherealxx"
@export_storage var license_type_hint := "Apache,MIT,CC-BY"

var variable_

@export var name := ""
@export var type := ""
#@export_custom(PROPERTY_HINT_ENUM, asset_type_list)
@export var ownership_type := ""
@export var creator := ""
@export var license_type := ""
@export_multiline var usage := ""
@export_multiline var modification := ""
@export var link := ""
@export var path := ""

var extension
var full_lisence

func get_enum_hint_pair():
	var pair : Dictionary[String, String] = {
		"type" = asset_type_hint,
		"ownership_type" = ownership_type_hint,
		"creator" = creator_hint,
		"license_type" = license_type_hint
	}
	return pair
