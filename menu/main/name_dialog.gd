extends Window


signal name_accepted
@export var easter_eggs: Dictionary[String, String]
@onready var _label: Label = $MarginContainer/VBoxContainer/Label


func _on_confirm_pressed() -> void:
	var result: Array[bool]
	var player_name: String = Game.validate_player_name((%LineEdit as LineEdit).text, 0, result)
	(%LineEdit as LineEdit).clear()
	if not result[0]:
		(%LineEdit as LineEdit).placeholder_text = "Недопустимое имя!"
		return
	Globals.set_string("player_name", player_name)
	name_accepted.emit()
	hide()
	print_verbose("Name set: %s." % player_name)


func _on_line_edit_text_changed(new_text: String) -> void:
	new_text = new_text.to_lower()
	if new_text.is_valid_ip_address():
		_label.text = "Что я тебе сделал?("
	elif new_text == "i'm blue":
		_label.add_theme_color_override(&"font_color", Color.BLUE)
		_label.text = "Дабудидай"
	elif new_text in ["dead circle", "666", "die"]:
		_label.text = "DIEEEEEEEEE"
		($CanvasModulate as CanvasItem).show()
	elif new_text in ["блять", "сука"] or new_text.contains("хуй") or new_text.contains("пизд") \
			or new_text.begins_with("еба") or new_text.contains("хуё") or new_text.contains("хуе"):
		_label.text = "Нехорошо материться!"
	elif new_text == "разраб клоун":
		(%LineEdit as LineEdit).text = "Сам такой!"
	elif new_text.begins_with("разраб"):
		($AnimationPlayer as AnimationPlayer).play(&"Developer")
	elif new_text in easter_eggs:
		_label.text = easter_eggs[new_text]
	else:
		_label.text = ""
		($AnimationPlayer as AnimationPlayer).play(&"RESET")
		($CanvasModulate as CanvasItem).hide()
