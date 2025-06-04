@tool
extends InspectorSpawner

enum PathLicenseStatus {
	INHERIT_NONE, INHERIT_PROJECT_WIDE,
	INHERIT_CLOSEST_PARENT_FOLDER, SELF_ASSIGNED
}

const LICENSE_DATABASE_SAVE_PATH := "res://alz_license_database.tres"
const RES_PATH := "res://"
#@onready var deselect_area: Control = $DeselectArea

@onready var current_path: TextEdit = %CurrentPath
@onready var pwl_dialog: ConfirmationDialog = %ProjectWideLicenseDialog
@onready var save_btn: Button = %SavePathLicenseBtn
@onready var exist_in_lic_db_info: VBoxContainer = %ExistInLicDBInfo
@onready var lic_inherit_info: VBoxContainer = %LicInheritInfo

#var mini_inspector_vbox : EditorInspector
var fsd_tree : Tree
#var fsd_last_selected_dir : String
var fsd_last_selected_file : String

var temp_pathlicencedata : PathLicenseData
var cached_alz_licdb : ALZProjectLicenseDatabase

func _ready() -> void:
	pass


func _addon_init():
	pwl_dialog.hide()
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
				
	#refill_inspector(DATA_TEST_2)
	#fsd_tree.print_tree_pretty()
	#mini_inspector.edit(load("res://addons/alicenzia/extend_resources/data_test.tres"))
	fsd_tree.cell_selected.connect(_on_filesystemdock_selectedpath_changed)
	
	%WarnIcon.texture = get_theme_icon("StatusWarning", "EditorIcons")
	#project_wide_license_dialog.confirmed.connect(_on_pwl_confirmed)

	%NoProjectLicenseWarn.visible = !is_pwl_exist() # !project_wide_license_dialog.is_pwl_exist()
	#exist_in_lic_db_info._addon_init()
	exist_in_lic_db_info.hide()
	lic_inherit_info._addon_init()
	lic_inherit_info.hide()
	
	#fsd_last_selected_dir = EditorInterface.get_current_directory()
	#fsd_last_selected_file = EditorInterface.get_current_path()
	#mini_inspector_vbox_ref.get_parent().size_flags
	#deselect_area.deselect.connect(_on_inspector_deselect)


func _miniinspector_anchor_sizeflag_override(_mini_inspector : ScrollContainer):
	_mini_inspector.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_mini_inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#mini_inspector.custom_minimum_size.y = self.custom_minimum_size.y + 30.0
	#mini_inspector.size_flags_vertical = SIZE_EXPAND_FILL
	_mini_inspector.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	pass


func _inspectorvbox_anchor_sizeflag_override(_mini_inspector_vbox : VBoxContainer):
	_mini_inspector_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	pass

	
func _on_filesystemdock_selectedpath_changed():
	# slight delay so that the signal reads the true current file
	await get_tree().create_timer(0.01, true, true, true).timeout
	#var new_current_dir := EditorInterface.get_current_directory()
	var new_current_file := EditorInterface.get_current_path()
	#print("%s | %s" % [new_current_dir, new_current_file])
	
	if new_current_file != fsd_last_selected_file:
		if new_current_file == "Favorites":
			return
		fsd_last_selected_file = new_current_file
		print("current file: %s" % fsd_last_selected_file)
		current_path.text = fsd_last_selected_file
		construct_license_inspector(fsd_last_selected_file)
		
		var dir = DirAccess.open(RES_PATH)
		
		if dir.dir_exists(fsd_last_selected_file):
			save_btn.text = "Save Per-Folder License"
		else:
			if dir.file_exists(fsd_last_selected_file):
				save_btn.text = "Save Per-File License"
			else:
				push_warning("type of path unknown")
		
		var db_cached := false # maybe not useful
		var db_exist := _check_license_database_exists()
		
		if not cached_alz_licdb:
			if db_exist:
				cached_alz_licdb = _get_license_database_or_null()
				db_cached = true
		else:
			db_cached = true
		
		var saved_licdata_found := false
		var lic_dict : Dictionary
		
		if cached_alz_licdb:
			lic_dict = cached_alz_licdb.path_license_dict
			var cleansed_path := _cleanse_dir_path(fsd_last_selected_file)
			if lic_dict.has(cleansed_path):
				temp_pathlicencedata = lic_dict[cleansed_path]
				saved_licdata_found = true
		
		if not saved_licdata_found:
			temp_pathlicencedata = PathLicenseData.new()
		
		exist_in_lic_db_info.set_text_by_existance(saved_licdata_found)
		
		refill_inspector(temp_pathlicencedata)
		
		var skip_search := _cleanse_dir_path(fsd_last_selected_file) == RES_PATH
		
		if skip_search:
			return
		
		var next_dir_to_search := _cleanse_dir_path(fsd_last_selected_file).get_base_dir()
		var parent_dir_license := ""
		
		# search for the closest parent per-folder license
		if cached_alz_licdb and not saved_licdata_found:
			var i := 0
			while (next_dir_to_search != RES_PATH):
				print(next_dir_to_search)
				if lic_dict.has(next_dir_to_search):
					var parent_dir_pld : PathLicenseData = lic_dict[next_dir_to_search]
					parent_dir_license = parent_dir_pld.license_type
					break
				next_dir_to_search = _cleanse_dir_path(next_dir_to_search).get_base_dir()
		
		if saved_licdata_found:
			lic_inherit_info.set_text_by_license_status(
				PathLicenseStatus.SELF_ASSIGNED, temp_pathlicencedata.license_type
				)
		elif not parent_dir_license.is_empty():
			lic_inherit_info.set_text_by_license_status(
				PathLicenseStatus.INHERIT_CLOSEST_PARENT_FOLDER, parent_dir_license
				)
		elif is_pwl_exist():
			lic_inherit_info.set_text_by_license_status(
				PathLicenseStatus.INHERIT_PROJECT_WIDE, _get_license_database_or_null().project_wide_license.license
				)
		else:
			lic_inherit_info.set_text_by_license_status(
				PathLicenseStatus.INHERIT_NONE, ""
				)


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


func _on_init_pwl_btn_pressed() -> void:
	if not pwl_dialog.visible:
		pwl_dialog.show()


func _on_project_wide_license_dialog_new_pwl_saved() -> void:
	%NoProjectLicenseWarn.hide()


func _check_license_database_exists() -> bool:
	var dir = DirAccess.open(RES_PATH)
	return dir.file_exists(LICENSE_DATABASE_SAVE_PATH)


func _get_license_database_or_null() -> ALZProjectLicenseDatabase:
	var dir = DirAccess.open(RES_PATH)
	var alz_licdb : ALZProjectLicenseDatabase
	 
	if _check_license_database_exists():
		print("file does exist")
		alz_licdb = ResourceLoader.load(
										LICENSE_DATABASE_SAVE_PATH,
										"",
										ResourceLoader.CACHE_MODE_REPLACE)
		return alz_licdb
	else:
		#alz_licdb = ALZProjectLicenseDatabase.new()
		return null


func _save_license_database(alz_licdb : ALZProjectLicenseDatabase):
	ResourceSaver.save(alz_licdb, LICENSE_DATABASE_SAVE_PATH)
	

func _cleanse_dir_path(dir_path : String) -> String:
	if dir_path == RES_PATH:
		return dir_path
	return dir_path.strip_edges().trim_suffix("/")
	

#@TODO add editor toast
func _on_save_path_license_btn_pressed() -> void:
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		alz_licdb = ALZProjectLicenseDatabase.new()
	
	# fill the path license dict with the path as key and the license data as the value
	alz_licdb.path_license_dict.set(
		_cleanse_dir_path(fsd_last_selected_file), temp_pathlicencedata)
	
	_save_license_database(alz_licdb)
	exist_in_lic_db_info.set_text_by_existance(true)
	lic_inherit_info.set_text_by_license_status(
		PathLicenseStatus.SELF_ASSIGNED, temp_pathlicencedata.license_type
	)


func is_pwl_exist() -> bool :
	var alz_licdb = _get_license_database_or_null()
	if alz_licdb:
		if alz_licdb.project_wide_license:
			return true
	return false


func _on_project_wide_license_dialog_confirmed() -> void:
	var new_pwl = ALZProjectWideLicense.new(
		pwl_dialog.get_owner_text(),
		pwl_dialog.get_license_text()
	)
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		alz_licdb = ALZProjectLicenseDatabase.new()
	
	alz_licdb.project_wide_license = new_pwl
	ResourceSaver.save(alz_licdb, LICENSE_DATABASE_SAVE_PATH)
	%NoProjectLicenseWarn.visible = false
	if cached_alz_licdb != alz_licdb:
		cached_alz_licdb = alz_licdb


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
