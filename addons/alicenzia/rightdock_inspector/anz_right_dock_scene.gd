@tool
extends InspectorSpawner

enum PathLicenseStatus {
	INHERIT_NONE, INHERIT_PROJECT_WIDE,
	INHERIT_CLOSEST_PARENT_FOLDER, SELF_ASSIGNED
}

const LICENSE_DATABASE_SAVE_PATH := "res://alz_license_database.tres"
const RES_PATH := "res://"

#@onready var deselect_area: Control = $DeselectArea

@onready var current_path_textbox: TextEdit = %CurrentPath
@onready var exist_in_lic_db_info: VBoxContainer = %ExistInLicDBInfo
@onready var lic_inherit_info: VBoxContainer = %LicInheritInfo
@onready var unsaved_changes_hbox: HBoxContainer = %UnsavedChangesHbox

@onready var pwl_dialog: ConfirmationDialog = %ProjectWideLicenseDialog
@onready var add_new_string_enum_dialog: ConfirmationDialog = %AddNewStringEnumDialog
@onready var confirm_remove_path_lic_dialog: ConfirmationDialog = %ConfirmRemovePathLicDialog

@onready var save_btn: Button = %SavePathLicenseBtn
@onready var remove_path_license_btn: Button = %RemovePathLicenseBtn
@onready var discard_changes_btn: Button = %DiscardChangesBtn

var tracked_signal_callable_pair : Dictionary[Signal, Callable]

var ed_theme : Theme 
var ed_toast : EditorToaster
#var mini_inspector_vbox : EditorInspector
var fsd_tree : Tree
#var fsd_last_selected_dir : String
var fsd_last_selected_file : String

var currently_edited_pld : PathLicenseData
var cached_alz_licdb : ALZProjectLicenseDatabase

var inspector_changed_unsaved := false
var empty_pld_ref : PathLicenseData


func _ready() -> void:
	#pwl_dialog.hide()
	pass


func _addon_init() -> void:
	ed_theme = EditorInterface.get_editor_theme()
	ed_toast = EditorInterface.get_editor_toaster()
	#pwl_dialog.hide()
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
				
	#fsd_tree.print_tree_pretty()
	
	
	%NoPWLWarnIcon.texture = get_theme_icon("StatusWarning", "EditorIcons")
	%UnsavedChangesWarningIcon.texture = get_theme_icon("NodeWarning", "EditorIcons")

	%NoProjectLicenseWarn.visible = !is_pwl_exist() # !project_wide_license_dialog.is_pwl_exist()
	#exist_in_lic_db_info._addon_init()
	
	for c: Control in \
	[exist_in_lic_db_info, lic_inherit_info, unsaved_changes_hbox,
	remove_path_license_btn, discard_changes_btn]:
		c.hide()
	
	for n: Node in \
	[lic_inherit_info, pwl_dialog]:
		if n.has_method("_addon_init"):
			n._addon_init()
			
	#fsd_tree.cell_selected.connect(_on_filesystemdock_selectedpath_changed)
	#add_new_string_enum_dialog.attempt_remove_hint_from_param.connect(_on_attempt_remove_hint_from_param)
	connect_and_track_signal(
		fsd_tree.cell_selected, _on_filesystemdock_selectedpath_changed)
	connect_and_track_signal(
		add_new_string_enum_dialog.attempt_remove_hint_from_param, _on_attempt_remove_hint_from_param)
	
	save_btn.disabled = true
	
	property_changed.connect(func():
		inspector_changed_unsaved = true
		# TODO check if the currently edited pld is empty/default on the inspector, if yes then disable the button
		discard_changes_btn.show()
		save_btn.disabled = false
		remove_path_license_btn.hide()
	)

	#deselect_area.deselect.connect(_on_inspector_deselect)


func connect_and_track_signal(obj_and_signal : Signal, callable_to_connect : Callable):
	obj_and_signal.connect(callable_to_connect)
	tracked_signal_callable_pair[obj_and_signal] = callable_to_connect


func _miniinspector_anchor_sizeflag_override(_mini_inspector : ScrollContainer) -> void:
	_mini_inspector.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_mini_inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#mini_inspector.custom_minimum_size.y = self.custom_minimum_size.y + 30.0
	#mini_inspector.size_flags_vertical = SIZE_EXPAND_FILL
	_mini_inspector.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO # unnecessary line
	pass


func _inspectorvbox_anchor_sizeflag_override(_mini_inspector_vbox : VBoxContainer) -> void:
	_mini_inspector_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	pass

	
func _on_filesystemdock_selectedpath_changed() -> void:
	if inspector_changed_unsaved:
		unsaved_changes_hbox.show()
		return
	# slight delay so that the signal reads the true current file
	await get_tree().create_timer(0.01, true, true, true).timeout
	_refresh_right_scene_dock()

	
func _refresh_right_scene_dock(force_refresh := false):
	#var new_current_dir := EditorInterface.get_current_directory()
	var new_current_file := EditorInterface.get_current_path()
	#print("%s | %s" % [new_current_dir, new_current_file])
	
	if new_current_file != fsd_last_selected_file or force_refresh:
		if new_current_file == "Favorites":
			return
		fsd_last_selected_file = new_current_file
		#print("current file: %s" % fsd_last_selected_file)
		current_path_textbox.text = fsd_last_selected_file
		current_path_textbox.animate_current_path_text()
		#construct_license_inspector(fsd_last_selected_file)
		
		empty_pld_ref = PathLicenseData.new() # so far no usage rn
		
		var dir = DirAccess.open(RES_PATH)
		
		var lic_context := ALZLicenseContext.new() # will be used later for checking inherits
		
		if dir.dir_exists(fsd_last_selected_file):
			save_btn.text = "Save Per-Folder License"
			lic_context.path_type = ALZLicenseContext.LicensePathType.FOLDER
		else:
			if dir.file_exists(fsd_last_selected_file):
				save_btn.text = "Save Per-File License"
				lic_context.path_type = ALZLicenseContext.LicensePathType.FILE
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
		
		var cleansed_path := _cleanse_dir_path(fsd_last_selected_file)
		
		if cached_alz_licdb:
			lic_dict = cached_alz_licdb.path_license_dict
			if lic_dict.has(cleansed_path):
				currently_edited_pld = lic_dict[cleansed_path]
				saved_licdata_found = true
		
		if not saved_licdata_found:
			currently_edited_pld = PathLicenseData.new()
			remove_path_license_btn.hide()
		else:
			remove_path_license_btn.show()
		
		exist_in_lic_db_info.set_text_by_existance(saved_licdata_found)
		
		
		#refill_inspector(temp_pathlicencedata)
		_refill_pathlicensedata_inspector(currently_edited_pld)
		
		# for now, skip if the dir path is res://
		var skip_search := cleansed_path == RES_PATH
		if skip_search:
			return
		
		var next_dir_to_search := cleansed_path.get_base_dir()
		var parent_dir_license := ""
		
		# search for the closest parent per-folder license
		if cached_alz_licdb and not saved_licdata_found:
			var i := 0
			while (next_dir_to_search != RES_PATH):
				#print(next_dir_to_search)
				if lic_dict.has(next_dir_to_search):
					var parent_dir_pld : PathLicenseData = lic_dict[next_dir_to_search]
					parent_dir_license = parent_dir_pld.license_type
					lic_context.license_parent_folder = next_dir_to_search.get_slice(
															"/",
															next_dir_to_search.get_slice_count("/") - 1
														)
					break
				next_dir_to_search = _cleanse_dir_path(next_dir_to_search).get_base_dir()
		
		lic_context.current_fsd_path = cleansed_path
		
		if saved_licdata_found:
			lic_context.inherit_type = ALZLicenseContext.LicenseInheritType.SELF_ASSIGNED
			lic_context.license_name = currently_edited_pld.license_type
		elif not parent_dir_license.is_empty():
			lic_context.inherit_type = ALZLicenseContext.LicenseInheritType.INHERIT_CLOSEST_PARENT_FOLDER
			lic_context.license_name = parent_dir_license
		elif is_pwl_exist():
			lic_context.inherit_type = ALZLicenseContext.LicenseInheritType.INHERIT_PROJECT_WIDE
			lic_context.license_name = _get_license_database_or_null().project_wide_license.license
		else:
			lic_context.inherit_type = ALZLicenseContext.LicenseInheritType.INHERIT_NONE
		
		lic_inherit_info.set_text_by_license_context(lic_context)


#func construct_license_inspector(fsd_last_selected_file): # wtf what does this one do?
	#pass


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		
		for cd: ConfirmationDialog in \
		[pwl_dialog, add_new_string_enum_dialog, confirm_remove_path_lic_dialog]:
			if cd:
				cd.hide()
		
		if mini_inspector:
			var inspector_parent := mini_inspector.get_parent()
			if inspector_parent:
				mini_inspector.get_parent().remove_child(mini_inspector)
			mini_inspector.queue_free()
		if fsd_tree:
			if fsd_tree.cell_selected.is_connected(_on_filesystemdock_selectedpath_changed):
				fsd_tree.cell_selected.disconnect(_on_filesystemdock_selectedpath_changed)
		
		for np : NodePath in ["%UnsavedChangesWarningIcon", "%NoPWLWarnIcon"]:
			var n : TextureRect = get_node_or_null(np)
			if n != null:
				n.texture = null

		pwl_dialog.hide()
		
		#print(tracked_signal_callable_pair)
		for s : Signal in tracked_signal_callable_pair.keys():
			var callable : Callable = tracked_signal_callable_pair[s]
			if s.is_connected(callable):
				s.disconnect(callable)
		
		tracked_signal_callable_pair.clear()


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
		#print("licensedb does exist")
		alz_licdb = ResourceLoader.load(
										LICENSE_DATABASE_SAVE_PATH,
										"",
										ResourceLoader.CACHE_MODE_REPLACE)
		return alz_licdb
	else:
		#alz_licdb = ALZProjectLicenseDatabase.new()
		return null


func _save_license_database(alz_licdb : ALZProjectLicenseDatabase) -> int:
	var err := ResourceSaver.save(alz_licdb, LICENSE_DATABASE_SAVE_PATH)
	#print("db updated")
	return err
	

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
		_cleanse_dir_path(fsd_last_selected_file), currently_edited_pld)
	
	_save_license_database(alz_licdb)
	exist_in_lic_db_info.set_text_by_existance(true)
	
	#lic_inherit_info.set_text_by_license_status(
		#PathLicenseStatus.SELF_ASSIGNED, temp_pathlicencedata.license_type
	#)
	inspector_changed_unsaved = false
	discard_changes_btn.hide()
	_refresh_right_scene_dock(true)


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
	
	alz_licdb.project_name = ProjectSettings.get("application/config/name")
	alz_licdb.project_wide_license = new_pwl
	ResourceSaver.save(alz_licdb, LICENSE_DATABASE_SAVE_PATH)
	%NoProjectLicenseWarn.visible = false
	if cached_alz_licdb != alz_licdb:
		cached_alz_licdb = alz_licdb


func _on_stringenumdropdown_addmore_btn_pressed(button_ref : Button, res_ref : Resource, prop_name_ref : String) -> void: # override
	%AddNewStringEnumDialog.show_and_setup(res_ref, prop_name_ref)


func _on_add_new_string_enum_dialog_confirmed() -> void:
	var updated_licdb : ALZProjectLicenseDatabase = %AddNewStringEnumDialog.assign_new_prop_option_to_res(
		_get_license_database_or_null()
	)
	if updated_licdb:
		_save_license_database(updated_licdb)
	#%AddNewStringEnumDialog.update_resdefault_changes()
	var updated_res : Resource = %AddNewStringEnumDialog.get_cached_edited_res()
	_refill_pathlicensedata_inspector(updated_res)


func _on_attempt_remove_hint_from_param(hint_to_remove : String) -> void:
	var updated_licdb : ALZProjectLicenseDatabase = %AddNewStringEnumDialog.remove_selected_hint_on_cached_res(
		hint_to_remove, _get_license_database_or_null()
	)
	if updated_licdb:
		_save_license_database(updated_licdb)
	
	await %AddNewStringEnumDialog.refresh_after_remove_hint()
	
	var updated_res : Resource = %AddNewStringEnumDialog.get_cached_edited_res()
	_refill_pathlicensedata_inspector(updated_res)


func _refill_pathlicensedata_inspector(pld_res : PathLicenseData) -> void:
	# check and update the type hints first
	var alz_licdb := _get_license_database_or_null()
	if alz_licdb:
		var sdc := alz_licdb.get_saved_default_changes_or_null("PathLicenseData")
		if sdc:
			for propname : String in sdc.propname_savedvalue_pairs.keys():
				var new_value = sdc.propname_savedvalue_pairs[propname]
				pld_res.set(propname, new_value)
				
	refill_inspector(pld_res)


func _on_discard_changes_btn_pressed() -> void:
	inspector_changed_unsaved = false
	unsaved_changes_hbox.hide()
	discard_changes_btn.hide()
	save_btn.disabled = true
	_refresh_right_scene_dock(true)


func _on_remove_path_license_btn_pressed() -> void:
	confirm_remove_path_lic_dialog.show_and_fill_path_info(
		_cleanse_dir_path(fsd_last_selected_file)
	)


func _on_confirm_remove_path_lic_dialog_confirmed() -> void:
	
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		return
	
	var cleansed_path := _cleanse_dir_path(fsd_last_selected_file)
	var _erase_successful := alz_licdb.path_license_dict.erase(cleansed_path)
	
	_save_license_database(alz_licdb)
	discard_changes_btn.hide()
	
	ed_toast.push_toast("Alicenzia: License data at %s successfully removed." % fsd_last_selected_file, EditorToaster.SEVERITY_INFO)
	_refresh_right_scene_dock(true)
