@tool
extends HBoxContainer

@export var param_name := "Param Name":
	set(new_name):
		param_name = new_name
		$Label.text = param_name

@export var show_separator := true:
	set(new_sep):
		show_separator = new_sep
		$VSeparator.visible = show_separator
