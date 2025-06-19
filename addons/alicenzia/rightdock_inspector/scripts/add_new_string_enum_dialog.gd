@tool
extends ConfirmationDialog

@onready var list_label: Label = $VBoxContainer/ListLabel
@onready var item_list: ItemList = $VBoxContainer/ItemList
@onready var new_item_pn_d: HBoxContainer = %NewItemPnD

var ok_btn : Button
var new_item_lineedit : LineEdit

# this cache system is flawed if used incorrectly :(
var edited_res_cache : Resource
var edited_param_cache : String
var param_options_cache : PackedStringArray
var typehint_varname_cache : String
var new_typehint_cache : String

func _ready() -> void:
	ok_btn = get_ok_button()
	ok_btn.disabled = true
	new_item_lineedit = new_item_pn_d.get_lineedit_node()
	
	new_item_lineedit.text_changed.connect(func(new_item_text : String):
		if (new_item_text.is_empty() or (new_item_text in param_options_cache)):
			ok_btn.disabled = true
		else:
			ok_btn.disabled = false
	)

func show_and_setup(res_to_edit : Resource, param_to_addnewoption : String):
	item_list.clear()
	
	# in theory the resource in question should always be PathLicenseData?
	if not res_to_edit.has_method("get_enum_hint_pair"):
		push_warning("resource don't have enum hint pair")
		return
	
	edited_res_cache = res_to_edit
	edited_param_cache = param_to_addnewoption
	
	var var_hint_pair : Dictionary[String, String] = res_to_edit.get_enum_hint_pair()
	if param_to_addnewoption in var_hint_pair.keys():
		var param_options_str := var_hint_pair[param_to_addnewoption]
		param_options_cache = param_options_str.split(",", false) # maybe turn it into static var next time
		print(param_options_cache)
		for opt : String in param_options_cache:
			item_list.add_item(opt)
	
	var cap_paramname := param_to_addnewoption.capitalize()
	title = 'Edit "%s" Option List' % cap_paramname
	list_label.text = "List of current options for %s:" % cap_paramname
	new_item_pn_d.param_name = "New %s" % cap_paramname
	self.show()


func assign_new_prop_option_to_res(alz_licdb : ALZProjectLicenseDatabase = null) -> Resource:
	var new_propoption := new_item_lineedit.text
	
	if edited_res_cache.has_method("get_enum_hint_pair"):
		var res_enum_name_pair : Dictionary[String,String] = edited_res_cache.get_enum_hint_name_pair()
		if edited_param_cache in res_enum_name_pair.keys():
			var type_hint_varname : String = res_enum_name_pair[edited_param_cache]
			#var old_type_hint := edited_res_cache.get(type_hint_varname)
			var new_propoption_list := param_options_cache
			new_propoption_list.append(new_propoption)
			new_propoption_list.sort()
			var new_type_hint := ",".join(new_propoption_list)
			edited_res_cache.set(type_hint_varname, new_type_hint)
			
			if alz_licdb:
				var existing_refdefchange : ALZResDefaultsChanges
				var edited_res_script_globalname : String = edited_res_cache.get_script().get_global_name()
				for refdefchange : ALZResDefaultsChanges in alz_licdb.saved_default_changes:
					if refdefchange.res_script_globalname == edited_res_script_globalname:
						existing_refdefchange = refdefchange
						break
				
				if not existing_refdefchange:
					existing_refdefchange = ALZResDefaultsChanges.new()
					existing_refdefchange.res_script_globalname = edited_res_script_globalname
					alz_licdb.saved_default_changes.append(existing_refdefchange)
				
				existing_refdefchange.propname_savedvalue_pairs[type_hint_varname] = new_type_hint
		
	edited_res_cache.set(edited_param_cache, new_propoption)
	#return edited_res_cache
	if alz_licdb:
		return alz_licdb
	return null


# Currently does not have a check if this the old or the one with the new typehint added
func get_cached_edited_res() -> Resource:
	return edited_res_cache

#func update_resdefault_changes(alz_licdb : ALZProjectLicenseDatabase, new):
	#if alz_licdb == null:
		#return
		#
	#var existing_refdefchange : ALZResDefaultsChanges
	#var edited_res_script_globalname : String = edited_res_cache.get_script().get_global_name()
	#for refdefchange : ALZResDefaultsChanges in alz_licdb.saved_default_changes:
		#if refdefchange.res_script_globalname == edited_res_script_globalname:
			#existing_refdefchange = refdefchange
			#break
	#
	#if not existing_refdefchange:
		#existing_refdefchange = ALZResDefaultsChanges.new()
		#existing_refdefchange.res_script_globalname = edited_res_script_globalname
	#
	#propname_savedvalue_pairs[edited_param_cache]
