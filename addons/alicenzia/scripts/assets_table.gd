@tool
extends VBoxContainer

@export_tool_button("Clear Row", "Callable") var action_clear = clear_row

func clear_row():
	for child : Node in get_children():
		if not child.is_in_group("first_row"):
			child.queue_free()
