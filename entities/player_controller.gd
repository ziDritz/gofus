class_name PlayerController
extends EntityController

# Player-specific
var local_player: bool = false  # Is this the local player?

# Input
var input_enabled: bool = true


func _ready() -> void:
	super._ready()
	is_player_controlled = true
	entity_data.entity_type = "player"


func _unhandled_input(event: InputEvent) -> void:
	if not local_player or not input_enabled:
		return
	
	if GameStateManager.is_in_exploration():
		_handle_exploration_input(event)
	elif GameStateManager.is_in_combat():
		_handle_combat_input(event)


## Handle input during exploration
func _handle_exploration_input(event: InputEvent) -> void:
	
	# Example: Click to move
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos = _world_to_grid(get_global_mouse_position())
		request_move(grid_pos)


## Handle input during combat
func _handle_combat_input(event: InputEvent) -> void:
	# Would show spell UI, handle targeting, etc.
	pass


## Request movement via command system
func request_move(target_pos: Vector2i) -> void:
	
	var command = {
		"type": "move",
		"entity_id": entity_id,
		"target_position": target_pos
	}
	
	CommandManager.queue_command(command)


## Request attack via command system
func request_attack(target_id: String, spell_id: String = "") -> void:
	
	var command = {
		"type": "attack",
		"entity_id": entity_id,
		"attacker_id": entity_id,
		"target_id": target_id,
		"spell_id": spell_id
	}
	
	CommandManager.queue_command(command)


## Convert world position to grid (inverse of _grid_to_world)
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	
	var tile_width = 43
	var tile_height = 21
	
	var x = roundi((world_pos.x / (tile_width / 2) + world_pos.y / (tile_height / 2)) / 2)
	var y = roundi((world_pos.y / (tile_height / 2) - world_pos.x / (tile_width / 2)) / 2)
	
	return Vector2i(x, y)
