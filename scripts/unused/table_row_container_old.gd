@tool
extends HBoxContainer
#class_name TableRowContainer extends HBoxContainer

@export_tool_button("list all childs", "Callable") var list_action = try_list

var is_adding_new_node := false
var is_checking_duplicate_bug := false
var duplicate_bug_found := false
var last_child_count : int = 0

func _ready() -> void:
	#tree_entered.connect(_on_table_row_entered_scenetree)
	child_entered_tree.connect(_on_new_child_added)
	child_order_changed.connect(_on_child_order_changed)
	
#func _on_table_row_entered_scenetree():
	#child_entered_tree.connect(_on_new_child_added)

func _on_child_order_changed():
	if is_checking_duplicate_bug:
		duplicate_bug_found = true
	print("order changed")
	#if not is_adding_new_node:
		#var has_buttons = check_if_all_child_has_buttons()
		#if not has_buttons: add_drag_button()

func try_list():
	print()
	
	if get_child_count() == 0:
		print("no childs")
		return
		
	var all_child_name_list : Array[String] = []
	for n in get_children():all_child_name_list.append(n.name)
	#
	var non_btn_child_name_list : Array[String] = []
	var filtered_childs := get_children().filter(func(child): if child is not TableRowDragButton: return child)
	for n in filtered_childs: non_btn_child_name_list.append(n.name)
	
	print("all childs: %s" % str(all_child_name_list))
	print("non btn childs: %s" % str(non_btn_child_name_list))
	
	print()

func add_drag_button():
	var current_child_count := get_child_count()
	if not is_adding_new_node and current_child_count >= 2:
		is_adding_new_node = true
		var filtered_childs := get_children().filter(func(child): return child is not TableRowDragButton)
		print(filtered_childs)
		for index : int in filtered_childs.size():
			if index == 0: continue
			print("idx: %d" % index)
			var child : Node = filtered_childs.get(index)
			print(child.name)
			var one_index_behind := child.get_index() - 1
			print("oneidxbhind: %s" % get_child(one_index_behind).name)
			if get_child(one_index_behind) is not TableRowDragButton:
				var new_dragbtn := TableRowDragButton.new()
				add_child(new_dragbtn)
				new_dragbtn.owner = get_tree().edited_scene_root
				move_child(new_dragbtn, child.get_index())
				await child_order_changed
				#await get_tree().create_timer(0.05, true, true).timeout
		#try_list()
		is_checking_duplicate_bug = true
		#await get_tree().create_timer(0.05, true, true).timeout
		is_checking_duplicate_bug = false
		is_adding_new_node = false
		
		##try_list()
		
		#if duplicate_bug_found:
			#duplicate_bug_found = false
			#add_drag_button()
		await get_tree().create_timer(0.2, true, true).timeout
		var has_buttons = check_if_all_child_has_buttons()
		if not has_buttons: add_drag_button()

func check_if_all_child_has_buttons() -> bool:
	var filtered_childs := get_children().filter(func(child): return child is not TableRowDragButton)
	for index : int in filtered_childs.size():
		if index == 0: continue
		var child : Node = filtered_childs.get(index)
		var one_index_behind := child.get_index() - 1
		if get_child(one_index_behind) is not TableRowDragButton:
			return false
	return true

func _on_new_child_added(recently_added_node : Node):
	if Engine.is_editor_hint() and recently_added_node is not TableRowDragButton:
		add_drag_button()
	#if Engine.is_editor_hint():
		#await recently_added_node.ready
		#print(recently_added_node.name)
		#print(str(recently_added_node.get_index()))
		#if not is_adding_new_node and recently_added_node.get_index() > 0:
			#is_adding_new_node = true
			#var new_dragbtn = TableRowDragButton.new()
			#add_child(new_dragbtn)
			#new_dragbtn.owner = get_tree().edited_scene_root
			#move_child(new_dragbtn, new_dragbtn.get_index() - 1)
			#new_dragbtn.set_control_to_adjust_node(get_child(new_dragbtn.get_index() - 1))
			#new_dragbtn.set_sibling_to_hold_node(recently_added_node) # front
			#
			## recheck sibling to test for duplicate
			#print(get_children())
			#await get_tree().create_timer(5.0, true, true)
			#print(get_children())
			#
			#print("done")
			#is_adding_new_node = false
			
	#if node is not TableRowDragButton:
		#var child_count := get_child_count()
		#if child_count >= 2:
			#var childs := self.get_children()
			#print(childs)
			#for index : int in child_count:
				#if index > 0: # second and up
					#var new_dragbtn = TableRowDragButton.new()
					#childs[index].add_sibling(new_dragbtn)
					#new_dragbtn.owner = get_tree().edited_scene_root
					#
					#if index >= 2:
						#print("broken")
						#break
