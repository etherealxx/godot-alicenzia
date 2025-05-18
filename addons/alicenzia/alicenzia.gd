@tool
extends EditorPlugin

const ALICENZIA_MAIN_WINDOW_SCENE_PATH = "uid://c321mhbnb88ir" #"uid://ch5mnmkieer5x"

var alicenzia_main_window_node : Node


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		load_addon_mainscreen()
		pass


func load_addon_mainscreen():
	alicenzia_main_window_node = load(ALICENZIA_MAIN_WINDOW_SCENE_PATH).instantiate()
	
	EditorInterface.get_editor_main_screen().add_child(alicenzia_main_window_node)
	_make_visible(false)


func _ready() -> void:
	if Engine.is_editor_hint():
		alicenzia_main_window_node.addon_refresh.connect(_on_addon_refresh)
		alicenzia_main_window_node._addon_init()


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		if alicenzia_main_window_node:
			#alicenzia_main_window_node.attempt_save_resource_changes()
			alicenzia_main_window_node.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if alicenzia_main_window_node:
		alicenzia_main_window_node.visible = visible


func _get_plugin_name():
	return "Alicenzia"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("CanvasLayer", "EditorIcons")


func _on_addon_refresh():
	var editor_main_screen : Node = EditorInterface.get_editor_main_screen()
	if editor_main_screen.is_ancestor_of(alicenzia_main_window_node):
		alicenzia_main_window_node.addon_refresh.disconnect(_on_addon_refresh)
		#scene_saved.disconnect(album_manager_node._on_any_scene_saved)
		alicenzia_main_window_node.queue_free()
		#remove_inspector_plugin(inspector_plugin_inst)
		load_addon_mainscreen()
		alicenzia_main_window_node.addon_refresh.connect(_on_addon_refresh)
		#scene_saved.connect(album_manager_node._on_any_scene_saved)
		alicenzia_main_window_node.visible = true
		alicenzia_main_window_node._addon_init()
		print("Alicenzia refreshed")
		print("---")


#func _save_external_data() -> void:
	#if album_manager_node:
		##@TODO currently it makes saving the resource twice. but might worth because it also saves before closing
		#album_manager_node.attempt_save_resource_changes()
