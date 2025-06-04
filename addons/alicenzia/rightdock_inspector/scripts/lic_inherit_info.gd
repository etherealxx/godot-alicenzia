@tool
extends VBoxContainer

enum PathLicenseStatus {
	INHERIT_NONE, INHERIT_PROJECT_WIDE,
	INHERIT_CLOSEST_PARENT_FOLDER, SELF_ASSIGNED
}

@export var panels_to_theme : Array[PanelContainer]

@onready var info_icon: TextureRect = %InfoIcon
@onready var label: RichTextLabel = %Label


func _addon_init() -> void:
	_cleanse_theme()
	
	for panel : PanelContainer in panels_to_theme:
		panel.set_theme( EditorInterface.get_editor_theme() )
		
		var editor_disabled_bg_color = panel.get_theme_color("disabled_bg_color", "Editor")
		var new_stylebox_panel := StyleBoxFlat.new()
		new_stylebox_panel.bg_color = editor_disabled_bg_color
		#new_stylebox_panel.border_color = editor_disabled_bg_color
		panel.add_theme_stylebox_override("panel", new_stylebox_panel)


#@TODO make license status a class, and add the file/folder type
func set_text_by_license_status(licstatus : PathLicenseStatus, lic_name : String):
	show()
	info_icon.texture = get_theme_icon("NodeInfo", "EditorIcons")
	
	match (licstatus):
		PathLicenseStatus.INHERIT_NONE:
			hide()
		PathLicenseStatus.INHERIT_PROJECT_WIDE:
			label.text = "Without a path-specific license, this file [b]inherits[/b] the [b]project-wide[/b] %s." % lic_name
		PathLicenseStatus.INHERIT_CLOSEST_PARENT_FOLDER:
			label.text = "Without a path-specific license, this file [b]inherits[/b] the [b]parent folder's[/b] %s." % lic_name
		PathLicenseStatus.SELF_ASSIGNED:
			hide()
	#if licdata_exists:
		#label.text = "License data for this path found on the database and loaded."
		#
	#else:
		#label.text = 	"This path has no license data saved in the database. " + \
						#"Create new one by filling the fields below and save."


func _cleanse_theme():
	for panel : PanelContainer in panels_to_theme:
		panel.remove_theme_stylebox_override("panel")
	info_icon.texture = null


func _exit_tree() -> void:
	_cleanse_theme()
