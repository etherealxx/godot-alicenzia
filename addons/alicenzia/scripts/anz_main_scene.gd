@tool
extends VBoxContainer

signal addon_refresh # addon


func _on_refresh_addon_btn_pressed() -> void:
	print("---")
	addon_refresh.emit()


func _on_refresh_table_btn_pressed() -> void:
	%AssetsTable.refresh()
