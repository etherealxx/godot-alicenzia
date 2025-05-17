extends VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

func _on_man_trig_btn_pressed() -> void:
	%TableContainer2.refresh()
