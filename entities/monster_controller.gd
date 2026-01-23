# scripts/entities/monster_controller.gd
class_name MonsterController
extends EntityController

# AI
@export var ai_type: String = "aggressive"  # "aggressive", "passive", "patrol"
@export var aggro_range: float = 5.0
@export var chase_range: float = 10.0

var current_target: String = ""
var ai_state: String = "idle"  # "idle", "patrol", "chase", "attack"


func _ready() -> void:
	super._ready()
	entity_data.entity_type = "monster"


func _process(delta: float) -> void:
	if not GameStateManager.is_in_exploration():
		return
	
	if not entity_data.can_act:
		return
	
	# Run AI
	_update_ai(delta)


## Simple AI behavior
func _update_ai(_delta: float) -> void:
	
	match ai_state:
		"idle":
			_ai_idle()
		"patrol":
			_ai_patrol()
		"chase":
			_ai_chase()
		"attack":
			_ai_attack()


## Idle behavior - look for targets
func _ai_idle() -> void:
	
	if ai_type == "passive":
		return
	
	# Look for players in range
	var nearby_players = EntityManager.get_entities_in_range(
		_grid_to_world(entity_data.grid_position),
		aggro_range,
		entity_data.map_id
	)
	
	for entity in nearby_players:
		if entity is PlayerController:
			current_target = entity.entity_id
			ai_state = "chase"
			break


## Patrol behavior
func _ai_patrol() -> void:
	# TODO: Implement patrol logic
	pass


## Chase target
func _ai_chase() -> void:
	
	var target = EntityManager.get_entity(current_target)
	if not target:
		ai_state = "idle"
		current_target = ""
		return
	
	# Check if in attack range
	if _is_adjacent(target):
		ai_state = "attack"
		return
		  
	# Check	if too far
	var distance = entity_data.grid_position.distance_to(target.entity_data.grid_position)
	if distance > chase_range:
		ai_state = "idle"
		current_target = ""
		return
		
	# Move toward target
	move_to(target.entity_data.grid_position)


## Attack target
func _ai_attack() -> void:
	var target = EntityManager.get_entity(current_target)
	if not target:
		ai_state = "idle"
		return

	# Check still in range
	if not _is_adjacent(target):
		ai_state = "chase"
		return

	# Attack
	attack(current_target)
	
