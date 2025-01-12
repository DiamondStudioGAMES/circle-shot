extends Control

signal save_requested

func _ready() -> void:
	($ShootAreaHSplit as SplitContainer).split_offset = \
			roundi(Globals.get_controls_vector2("shoot_area").x)
	($ShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset = \
			roundi(Globals.get_controls_vector2("shoot_area").y)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when visible:
			_on_quit_pressed()


func _on_quit_pressed() -> void:
	queue_free()


func _on_discard_pressed() -> void:
	propagate_call(&"_ready")


func _on_save_pressed() -> void:
	save_requested.emit()


func _on_save_requested() -> void:
	Globals.set_controls_vector2("shoot_area", Vector2(
			($ShootAreaHSplit as SplitContainer).split_offset,
			($ShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset
	))
