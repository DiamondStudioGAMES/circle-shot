class_name Throwable
extends Weapon

## Узел оружия класса "Бросаемое".

## Сцена снаряда.
@export var projectile_scene: PackedScene
## Сцена боеприпаса.
@export var ammo_scene: PackedScene
## Время, за которое боеприпас встаёт в магазин.
@export var to_aim_time := 0.15
## Угол между боеприпасами (в градусах).
@export var angle_between_ammo := 10.0
## Интервал между бросками. Должен быть больше либо равным времени анимации броска.
@export var throw_interval := 0.5
## Базовый разброс снаряда.
@export var spread_base := 1.0
## На сколько повысится разброс снаряда при ходьбе.
@export var spread_walk := 5.0
## Множитель для определения максимальной скорости, при которой разброс
## при движении не будет добавляться.
@export_range(0.0, 1.0) var spread_walk_ratio := 0.5

var _throw_timer := 0.0
var _reloading := false
var _interrupt_reload := false
var _turn_tween: Tween

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _throw_point: Marker2D = $ThrowPivot/ThrowPoint
@onready var _throw_pivot: Marker2D = $ThrowPivot
@onready var _ammo_parent: Marker2D = $Ammo

@onready var _aim: Line2D = $ThrowPivot/ThrowPoint/Aim
@onready var _aim_spread_left: Line2D = $ThrowPivot/ThrowPoint/Aim/SpreadLeft
@onready var _aim_spread_right: Line2D = $ThrowPivot/ThrowPoint/Aim/SpreadRight


func _process(_delta: float) -> void:
	_aim.hide()
	
	if can_shoot():
		_aim.visible = _player.player_input.showing_aim
		_throw_pivot.rotation = _calculate_aim_angle()
		
		_aim_spread_left.rotation_degrees = -_calculate_spread()
		_aim_spread_right.rotation_degrees = _calculate_spread()
	
	if _reloading and _player.player_input.shooting:
		_interrupt_reload = true


func _physics_process(delta: float) -> void:
	if multiplayer.is_server() and can_shoot() and _player.player_input.shooting \
			and ammo > 0 and _throw_timer <= 0.0:
		shoot.rpc()
	_throw_timer -= delta
	if _player.is_local() and can_reload() and ammo <= 0:
		_player.try_reload_weapon()


func _initialize() -> void:
	for i: int in ammo_per_load:
		var ammo_node: Node2D = ammo_scene.instantiate()
		ammo_node.rotation_degrees = angle_between_ammo * (-i + (ammo_per_load - 1) / 2.0)
		_ammo_parent.add_child(ammo_node)


func _shoot() -> void:
	ammo -= 1
	_throw_timer = throw_interval
	
	var current_ammo: Node2D = _ammo_parent.get_child(ammo)
	var current_ammo_anim: AnimationPlayer = current_ammo.get_node(^"AnimationPlayer")
	
	var throw_anim: Animation = current_ammo_anim.get_animation(&"Throw")
	throw_anim.track_set_key_value(0, 1, current_ammo.to_local(_throw_pivot.global_position))
	current_ammo_anim.play(&"Throw")
	var anim_name: StringName = await current_ammo_anim.animation_finished
	if anim_name != &"Throw":
		ammo += 1
		return
	
	var angle: float = _player.player_input.aim_direction.angle()
	var post_throw_anim: Animation = current_ammo_anim.get_animation(&"PostThrow")
	post_throw_anim.track_set_key_value(0, 0, current_ammo.to_local(_throw_pivot.global_position))
	post_throw_anim.track_set_key_value(0, 1, current_ammo.to_local(_throw_point.global_position))
	var parent_angle: float = _ammo_parent.rotation + current_ammo.rotation
	post_throw_anim.track_set_key_value(1, 1, _calculate_aim_angle() - parent_angle)
	current_ammo_anim.play(&"PostThrow")
	anim_name = await current_ammo_anim.animation_finished
	if anim_name != &"PostThrow":
		ammo += 1
		return
	
	current_ammo.hide()
	if multiplayer.is_server():
		_create_projectile(angle)


func _make_current() -> void:
	_anim.play(&"Equip")
	block_shooting()
	await _anim.animation_finished
	unlock_shooting()


func _unmake_current() -> void:
	if is_instance_valid(_turn_tween):
		_turn_tween.custom_step(to_aim_time)
	_throw_timer = 0.0
	
	_anim.play(&"RESET")
	_anim.advance(0.01)
	for ammo_node: Node2D in _ammo_parent.get_children():
		(ammo_node.get_node(^"AnimationPlayer") as AnimationPlayer).play(&"RESET")
		(ammo_node.get_node(^"AnimationPlayer") as AnimationPlayer).advance(0.01)


func _can_reload() -> bool:
	return _throw_timer <= 0.0


func reload() -> void:
	_reloading = true
	block_shooting()
	
	while ammo != ammo_per_load and ammo_in_stock >= 0:
		var current_ammo: Node2D = _ammo_parent.get_child(ammo)
		var current_ammo_anim: AnimationPlayer = current_ammo.get_node(^"AnimationPlayer")
		
		current_ammo.show()
		current_ammo.rotation = 0.0
		current_ammo_anim.play(&"Reload")
		current_ammo_anim.advance(0.0)
		var anim_name: StringName = await current_ammo_anim.animation_finished
		if anim_name != &"Reload":
			_reloading = false
			_interrupt_reload = false
			current_ammo.hide()
			unlock_shooting()
			return
		
		_turn_tween = create_tween()
		_turn_tween.tween_property(current_ammo, ^":rotation_degrees",
				angle_between_ammo * (-ammo + (ammo_per_load - 1) / 2.0), to_aim_time)
		ammo += 1
		ammo_in_stock -= 1
		_player.ammo_text_updated.emit(get_ammo_text())
		
		if _interrupt_reload:
			break
	
	_reloading = false
	_interrupt_reload = false
	unlock_shooting()


func _create_projectile(angle: float) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.position = _throw_point.global_position
	projectile.damage_multiplier = _player.damage_multiplier
	var spread: float = _calculate_spread()
	projectile.rotation = angle + deg_to_rad(randf_range(-spread, spread))
	projectile.scale.y = -1 if projectile.rotation > PI / 2 or projectile.rotation < -PI / 2 else 1
	projectile.team = _player.team
	projectile.who = _player.id
	projectile.name += str(randi())
	_projectiles_parent.add_child(projectile)


func _calculate_spread() -> float:
	return spread_walk * clampf((_player.entity_input.direction.length() - spread_walk_ratio)
			/ (1.0 - spread_walk_ratio), 0.0, 1.0) + spread_base
