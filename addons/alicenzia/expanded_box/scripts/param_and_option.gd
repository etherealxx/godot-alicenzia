@tool
extends HBoxContainer

@export var param_name := "Param Name":
	set(new_name):
		param_name = new_name
		$Label.text = param_name

@export var show_add_button := true:
	set(new_add):
		show_add_button = new_add
		var btn : Button = $OptionAndPlus.get_add_btn()
		btn.visible = show_add_button

@export var show_separator := true:
	set(new_sep):
		show_separator = new_sep
		$VSeparator.visible = show_separator

@export var options : Array[String]:
	set(new_opt):
		options = new_opt
		var opt : OptionButton = $OptionAndPlus.get_option_btn()
		opt.clear()
		if options.size() > 0:
			for item : String in options:
				if !item.is_empty():
					opt.add_item(item)


func get_value() -> String:
	return $OptionAndPlus.get_value()
