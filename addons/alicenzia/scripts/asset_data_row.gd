@tool
extends HBoxContainer

@onready var asset_name: Label = $AssetName
@onready var asset_type: OptionButton = $AssetType
@onready var asset_extension: Label = $AssetExtension
@onready var asset_ownership_type: OptionButton = $AssetOwnType
@onready var asset_creator: OptionButton = $AssetCreator
@onready var asset_license: OptionButton = $AssetLicense
@onready var asset_usage: LineEdit = $AssetUsage
@onready var asset_mods: LineEdit = $AssetMods
@onready var asset_link: LineEdit = $AssetLink
@onready var asset_path: LineEdit = $AssetPath
@onready var view_full_lisence_btn: Button = $ViewFullLisenceBtn


func fill_data(file_path : String):
	var file_name := file_path.get_file()
	asset_name.text = file_name
	asset_extension.text = file_name.get_slice(
		".", file_name.get_slice_count(".") - 1).to_lower()
	asset_path.text = file_path
