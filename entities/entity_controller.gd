# scripts/entities/entity_controller.gd
class_name EntityController
extends Node2D

## Controls entity logic and behavior - all visuals delegated to EntityVisuals

#region Signals

signal attack_executed(target_position: Vector2)
signal damage_taken(amount: int, damage_type: String)
signal movement_started()
signal movement_completed()

#endregion

#region Components

@export var entity_data: EntityData
var entity_visuals: EntityVisuals

#endregion

#region State

var entity_id: String = ""
var is_player_controlled: bool = false
var current_path: Array[Vector2i] = []
var is_moving: bool = false
var movement_speed: float = 200.0

#endregion

#region Lifecycle

func _ready() -> void:
	if not entity_data:
		entity_data = EntityData.new()
	
	if entity_id.is_empty():
		entity_id = _generate_entity_id()
	
	entity_data.entity_id = entity_id
	
	entity_visuals = get_node_or_null("EntityVisuals")
	if entity_visuals:
		entity_visuals.entity_controller = self
		entity_visuals.entity_data = entity_data
	
	EntityManager.register_entity(self, entity_id)
	_connect_data_signals()


func _exit_tree() -> void:
	EntityManager.unregister_entity(entity_id)

#endregion

#region Initialization

func initialize(id: String, data: EntityData) -> void:
	entity_id = id
	entity_data = data
	entity_data.entity_id = id


func _generate_entity_id() -> String:
	return "entity_%s_%d" % [entity_data.entity_type, Time.get_ticks_msec()]


func _connect_data_signals() -> void:
	entity_data.died.connect(_on_entity_died)

#endregion

#region Command Processing

func move_to(target_grid_pos: Vector2i) -> bool:
	if not entity_data.can_act or entity_data.is_moving:
		return false
	
	current_path = _calculate_path(entity_data.grid_position, target_grid_pos)
	
	if current_path.is_empty():
		return false
	
	var mp_cost = current_path.size()
	
	if not entity_data.spend_movement_points(mp_cost):
		return false
	
	_start_movement()
	return true


func attack(target_id: String, spell_id: String = "") -> bool:
	if not entity_data.can_act:
		return false
	
	var target = EntityManager.get_entity(target_id)
	if not target:
		return false
	
	var ap_cost = 3
	
	if not entity_data.spend_action_points(ap_cost):
		return false
	
	_execute_attack(target, spell_id)
	
	return true


func use_item(item_id: String) -> bool:
	return false


func interact_with(target_id: String) -> bool:
	var target = EntityManager.get_entity(target_id)
	if not target:
		return false
	
	if not _is_adjacent(target):
		return false
	
	EventBus.interaction_requested.emit(entity_id, target_id)
	
	return true

#endregion

#region Movement Implementation

func _calculate_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	
	var current = from
	while current != to:
		if current.x < to.x:
			current.x += 1
		elif current.x > to.x:
			current.x -= 1
		elif current.y < to.y:
			current.y += 1
		elif current.y > to.y:
			current.y -= 1
		
		path.append(current)
	
	return path


func _start_movement() -> void:
	entity_data.is_moving = true
	movement_started.emit()
	EventBus.movement_started.emit(entity_id, entity_data.grid_position, current_path[-1])
	
	_move_to_next_cell()


func _move_to_next_cell() -> void:
	if current_path.is_empty():
		_complete_movement()
		return
	
	var next_cell = current_path.pop_front()
	entity_data.set_grid_position(next_cell)
	
	var world_pos = _grid_to_world(next_cell)
	var tween = create_tween()
	tween.tween_property(self, "position", world_pos, 0.3)
	tween.finished.connect(_move_to_next_cell)


func _complete_movement() -> void:
	entity_data.is_moving = false
	movement_completed.emit()
	EventBus.movement_completed.emit(entity_id, entity_data.grid_position)


func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	var tile_width = 43
	var tile_height = 21
	
	return Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2,
		(grid_pos.x + grid_pos.y) * tile_height / 2
	)

#endregion

#region Fight Implementation

func _execute_attack(target: EntityController, spell_id: String) -> void:
	var base_damage = entity_data.get_stat("strength") * 2
	var damage = roundi(base_damage)
	
	target.take_damage(damage, entity_id, "physical")
	
	attack_executed.emit(target.global_position)


func take_damage(amount: int, attacker_id: String, damage_type: String) -> void:
	var resistance = entity_data.get_stat("armor")
	var final_damage = max(1, amount - roundi(resistance * 0.5))
	
	entity_data.modify_health(-final_damage)
	
	EventBus.damage_dealt.emit(attacker_id, entity_id, final_damage, damage_type)
	damage_taken.emit(final_damage, damage_type)

#endregion

#region Turn Management

func start_turn() -> void:
	entity_data.start_turn()
	EventBus.turn_started.emit(entity_id, 0)


func end_turn() -> void:
	entity_data.end_turn()
	EventBus.turn_ended.emit(entity_id)

#endregion

#region Data Event Handlers

func _on_entity_died() -> void:
	await get_tree().create_timer(2.0).timeout
	queue_free()

#endregion

#region Utility

func _is_adjacent(other: EntityController) -> bool:
	var dist = entity_data.grid_position.distance_to(other.entity_data.grid_position)
	return dist <= 1.5


func on_spawned() -> void:
	if entity_visuals:
		entity_visuals.on_spawned()


func on_despawned() -> void:
	if entity_visuals:
		entity_visuals.on_despawned()

#endregion
