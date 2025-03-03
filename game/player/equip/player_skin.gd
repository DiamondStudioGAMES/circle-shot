class_name PlayerSkin
extends Sprite2D

## Скин игрока.

## Сцена с пользовательским эффектом получения урона. Должна самоуничтожаться после воспроизведения 
## эффекта, чтобы не вызывать утечек памяти. НЕ следует за игроком.
@export var custom_hurt_vfx_scene: PackedScene
## Сцена с пользовательским эффектом смерти. Должна самоуничтожаться после воспроизведения эффекта,
## чтобы не вызывать утечек памяти.
@export var custom_death_vfx_scene: PackedScene
## Сцена с пользовательским эффектом лечения. Должна самоуничтожаться после воспроизведения эффекта,
## чтобы не вызывать утечек памяти. НЕ следует за игроком.
@export var custom_heal_vfx_scene: PackedScene
## Сцена с пользовательским эффектом кровотечения. Корневой узел должен наследоваться от
## [CPUParticles2D]. Эффект включается/выключается через [member CPUParticles2D.emitting].
@export var custom_blood_scene: PackedScene
## Ссылка на ресурс с данными этого скина.
var data: SkinData
## Игрок, которому принадлежит этот объект скина.
var player: Player

var _cached_default_hurt_vfx_scene: PackedScene
var _cached_default_heal_vfx_scene: PackedScene
var _cached_default_death_vfx_scene: PackedScene
var _cached_default_blood: CPUParticles2D


## Инициализирует скин игроком [param to_player] и данными [param skin_data].
func initialize(to_player: Player, skin_data: SkinData) -> void:
	player = to_player
	data = skin_data
	if custom_hurt_vfx_scene:
		_cached_default_hurt_vfx_scene = player.hurt_vfx_scene
		player.hurt_vfx_scene = custom_hurt_vfx_scene
	if custom_heal_vfx_scene:
		_cached_default_heal_vfx_scene = player.heal_vfx_scene
		player.heal_vfx_scene = custom_heal_vfx_scene
	if custom_death_vfx_scene:
		_cached_default_death_vfx_scene = player.death_vfx_scene
		player.death_vfx_scene = custom_death_vfx_scene
	if custom_blood_scene:
		var blood: CPUParticles2D = custom_blood_scene.instantiate()
		var emitting: bool = player.blood.emitting
		_cached_default_blood = player.blood
		player.blood.replace_by(blood)
		player.blood = blood
		player.blood.emitting = emitting
	_initialize()


## Удаляет скин.
func finalize() -> void:
	_finalize()
	if _cached_default_hurt_vfx_scene:
		player.hurt_vfx_scene = _cached_default_hurt_vfx_scene
	if _cached_default_heal_vfx_scene:
		player.heal_vfx_scene = _cached_default_heal_vfx_scene
	if _cached_default_death_vfx_scene:
		player.death_vfx_scene = _cached_default_death_vfx_scene
	if is_instance_valid(_cached_default_blood):
		var blood: CPUParticles2D = player.blood
		var emitting: bool = blood.emitting
		player.blood.replace_by(_cached_default_blood)
		player.blood = _cached_default_blood
		player.blood.emitting = emitting
		blood.queue_free()
	queue_free()


## Метод для переопределения. Вызывается в момент инициализации.
func _initialize() -> void:
	pass


## Метод для переопределения. Вызывается в момент удаления скина.
func _finalize() -> void:
	pass
