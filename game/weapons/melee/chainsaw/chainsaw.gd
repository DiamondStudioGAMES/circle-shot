extends Melee

@onready var _attack_sfx: AudioStreamPlayer2D = $AttackSfx

func _shoot() -> void:
	_shoot_timer = shoot_interval
	_anim.play(&"Attack")
	_anim.seek(0.0, true)
	
	if not _attack_sfx.playing:
		_attack_sfx.play()
	
	if multiplayer.is_server():
		_attack.damage_multiplier = player.damage_multiplier
		_attack.team = player.team
		_attack.who = player.id


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"Attack":
		_anim.play(&"Idle")
