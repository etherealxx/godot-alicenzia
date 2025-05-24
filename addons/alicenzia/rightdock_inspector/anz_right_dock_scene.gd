@tool
extends InspectorSpawner

const DATA_TEST = preload("res://addons/alicenzia/extend_resources/data_test.tres")
const DATA_TEST_2 = preload("res://addons/alicenzia/extend_resources/data_test_2.tres")
#@onready var deselect_area: Control = $DeselectArea

@onready var current_path: TextEdit = $CurrentPath
@onready var project_wide_license_dialog: ConfirmationDialog = $ProjectWideLicenseDialog

#var mini_inspector_vbox : EditorInspector
var fsd_tree : Tree
var fsd_last_selected_dir : String
var fsd_last_selected_file : String


func _ready() -> void:
	pass


func _addon_init():
	inspector_below_here = %InspectorBelowHere
	# mini_inspector_vbox = instantiate_inspector(DATA_TEST)
	instantiate_inspector()
	
	var ed = EditorInterface.get_file_system_dock()
	
	for child : Node in ed.get_children():
		if child.get_child_count() > 0:
			var gc = child.get_child(0)
			if gc is Tree:
				fsd_tree = gc
				break
				
	refill_inspector(DATA_TEST_2)
	#fsd_tree.print_tree_pretty()
	#mini_inspector.edit(load("res://addons/alicenzia/extend_resources/data_test.tres"))
	fsd_tree.cell_selected.connect(_on_filesystemdock_selectedpath_changed)
	
	%WarnIcon.texture = get_theme_icon("StatusWarning", "EditorIcons")
	#project_wide_license_dialog.confirmed.connect(_on_pwl_confirmed)

	$NoProjectLicenseWarn.visible = !project_wide_license_dialog.is_pwl_exist()
	#fsd_last_selected_dir = EditorInterface.get_current_directory()
	#fsd_last_selected_file = EditorInterface.get_current_path()
	#mini_inspector_vbox_ref.get_parent().size_flags
	#deselect_area.deselect.connect(_on_inspector_deselect)


func _miniinspector_anchor_sizeflag_override(_mini_inspector : ScrollContainer):
	mini_inspector.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	#mini_inspector.custom_minimum_size.y = self.custom_minimum_size.y + 30.0
	#mini_inspector.size_flags_vertical = SIZE_EXPAND_FILL
	_mini_inspector.vertical_scroll_mode = 0
	pass


func _inspectorvbox_anchor_sizeflag_override(_mini_inspector_vbox : VBoxContainer):
	mini_inspector_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	pass

#func _on_pwl_confirmed():
	#var new_pwl = ALZProjectWideLicense.new(
		#
	#)
	
func _on_filesystemdock_selectedpath_changed():
	# slight delay so that the signal reads the true current file
	await get_tree().create_timer(0.01, true, true, true).timeout
	#var new_current_dir := EditorInterface.get_current_directory()
	var new_current_file := EditorInterface.get_current_path()
	#print("%s | %s" % [new_current_dir, new_current_file])
	
	if new_current_file != fsd_last_selected_file:
		fsd_last_selected_file = new_current_file
		print("current file: %s" % fsd_last_selected_file)
		current_path.text = fsd_last_selected_file
		construct_license_inspector(fsd_last_selected_file)
	#elif new_current_dir != fsd_last_selected_dir:
		#fsd_last_selected_dir = new_current_dir
		#print("current dir: %s" % fsd_last_selected_dir)

func construct_license_inspector(fsd_last_selected_file):
	pass


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		if mini_inspector:
			mini_inspector.get_parent().remove_child(mini_inspector)
			mini_inspector.queue_free()
		if fsd_tree:
			if fsd_tree.cell_selected.is_connected(_on_filesystemdock_selectedpath_changed):
				fsd_tree.cell_selected.disconnect(_on_filesystemdock_selectedpath_changed)
		%WarnIcon.texture = null
#func _on_inspector_deselect():
	#if mini_inspector_vbox_ref:
		#for _edprop in mini_inspector_vbox.get_children():
			#var edprop = _edprop
			#if edprop is HBoxContainer:
				#if edprop.get_child(0) is EditorProperty:
					#edprop = _edprop.get_child(0)
			#if edprop is EditorProperty:
				#if edprop.is_selected():
					#edprop.deselect()
							
#func _propname_matchcase_override(res_to_edit : Resource, prop_name : String):
	#match prop_name:
		#prop_title_varname:
			#song_title_label.text = res_to_edit.get(prop_name)

#func _prop_changed_override(prop : String, value : Variant):
	#if prop == prop_title_varname:
		#song_title_label.text = value
	#pass

#func fill_data(data : Resource):
	#song_data = data
	#instantiate_inspector(song_data)
	#init_panel()

#func print_prop(res : Resource):
	#print("---")
	#for prop_dict : Dictionary in res.get_property_list():
		#print(prop_dict)
	#print("---")

#func _on_remove_btn_pressed() -> void:
	#EditorInterface.mark_scene_as_unsaved()
	#remove_this_panel.emit()


func _on_init_pwl_btn_pressed() -> void:
	if not project_wide_license_dialog.visible:
		project_wide_license_dialog.show()


func _on_project_wide_license_dialog_new_pwl_saved() -> void:
	$NoProjectLicenseWarn.hide()
