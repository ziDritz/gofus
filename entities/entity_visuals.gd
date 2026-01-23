# scripts/entities/entity_visuals.gd
class_name EntityVisuals
extends Node2D

## Visual representation of an entity - handles all sprites, animations, and VFX

#region References

@export var entity_controller: EntityController
@export var entity_data: EntityData

#endregion

#region Visual Components

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var nameplate: Label = $Nameplate
@onready var health_bar: ProgressBar = $HealthBar
@onready var status_effect_container: HBoxContainer = $StatusEffectContainer
@onready var selection_indicator: Sprite2D = $SelectionIndicator

#endregion

#region Animation State

var current_animation: String = "idle"
var facing_direction: Vector2 = Vector2.RIGHT

#endregion

#region Lifecycle

func _ready() -> void:
	_connect_signals()
	_sync_initial_visuals()

#endregion

#region Signal Connections

func _connect_signals() -> void:
	if entity_data:
		entity_data.health_changed.connect(_on_health_changed)
		entity_data.max_health_changed.connect(_on_max_health_changed)
		entity_data.stat_changed.connect(_on_stat_changed)
		entity_data.position_changed.connect(_on_position_changed)
		entity_data.status_effect_added.connect(_on_status_effect_added)
		entity_data.status_effect_removed.connect(_on_status_effect_removed)
		entity_data.died.connect(_on_died)
	
	if entity_controller:
		if entity_controller.has_signal("attack_executed"):
			entity_controller.attack_executed.connect(_on_attack_executed)
		if entity_controller.has_signal("damage_taken"):
			entity_controller.damage_taken.connect(_on_damage_taken)
		if entity_controller.has_signal("movement_started"):
			entity_controller.movement_started.connect(_on_movement_started)
		if entity_controller.has_signal("movement_completed"):
			entity_controller.movement_completed.connect(_on_movement_completed)

#endregion

#region Initial Sync

func _sync_initial_visuals() -> void:
	if not entity_data:
		return
	
	if nameplate:
		nameplate.text = entity_data.entity_name
	
	if health_bar:
		health_bar.max_value = entity_data.stats["max_health"]
		health_bar.value = entity_data.stats["health"]
	
	_play_animation("idle")
	
	if selection_indicator:
		selection_indicator.visible = false

#endregion

#region Animation Control

func _play_animation(anim_name: String) -> void:
	if not sprite or not sprite.sprite_frames:
		return
	
	if not sprite.sprite_frames.has_animation(anim_name):
		push_warning("[EntityVisuals] Animation '%s' not found" % anim_name)
		return
	
	current_animation = anim_name
	sprite.play(anim_name)


func _play_animation_once(anim_name: String) -> void:
	if not sprite:
		return
	
	_play_animation(anim_name)
	
	await sprite.animation_finished
	_play_animation("idle")


func _update_sprite_direction() -> void:
	if not sprite:
		return
	
	sprite.flip_h = facing_direction.x < 0

#endregion

#region Data Signal Handlers

func _on_health_changed(old_value: int, new_value: int) -> void:
	if health_bar:
		var tween = create_tween()
		tween.tween_property(health_bar, "value", new_value, 0.3)
	
	if new_value < old_value:
		_flash_damage()


func _on_max_health_changed(old_value: int, new_value: int) -> void:
	if health_bar:
		health_bar.max_value = new_value


func _on_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
	pass


func _on_position_changed(old_pos: Vector2i, new_pos: Vector2i) -> void:
	pass


func _on_status_effect_added(effect_id: String) -> void:
	_update_status_effect_icons()


func _on_status_effect_removed(effect_id: String) -> void:
	_update_status_effect_icons()


func _on_died() -> void:
	_play_death_sequence()

#endregion

#region Controller Signal Handlers

func _on_attack_executed(target_position: Vector2) -> void:
	_play_attack_animation(target_position)


func _on_damage_taken(amount: int, damage_type: String) -> void:
	_show_damage_number(amount, damage_type)
	_play_hurt_animation()


func _on_movement_started() -> void:
	_play_animation("walk")


func _on_movement_completed() -> void:
	_play_animation("idle")

#endregion

#region Visual Effects

func _flash_damage() -> void:
	if not sprite:
		return
	
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _play_attack_animation(target_pos: Vector2) -> void:
	facing_direction = (target_pos - global_position).normalized()
	_update_sprite_direction()
	
	_play_animation_once("attack")


func _play_hurt_animation() -> void:
	_flash_damage()
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hurt"):
		_play_animation_once("hurt")


func _play_death_sequence() -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		_play_animation("death")
		await sprite.animation_finished
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		await tween.finished
	
	visible = false


func _show_damage_number(amount: int, damage_type: String) -> void:
	pass


func _update_status_effect_icons() -> void:
	if not status_effect_container or not entity_data:
		return
	
	for child in status_effect_container.get_children():
		child.queue_free()
	
	for effect in entity_data.status_effects:
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(16, 16)
		status_effect_container.add_child(icon)

#endregion

#region Selection/Highlight

func show_selection(show: bool = true) -> void:
	if selection_indicator:
		selection_indicator.visible = show


func set_highlight(enabled: bool) -> void:
	if not sprite:
		return
	
	if enabled:
		sprite.modulate = Color(1.2, 1.2, 1.2)
	else:
		sprite.modulate = Color.WHITE

#endregion

#region Spawn/Despawn

func on_spawned() -> void:
	visible = true
	_sync_initial_visuals()
	_play_animation("idle")


func on_despawned() -> void:
	visible = false

#endregion
