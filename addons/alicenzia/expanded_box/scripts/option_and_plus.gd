@tool
extends HBoxContainer

func get_option_btn() -> OptionButton:
	return $OptionButton

func get_add_btn() -> Button:
	return $Button

func get_value() -> String:
	return 	$OptionButton.get_item_text(
			$OptionButton.get_selected_id())
