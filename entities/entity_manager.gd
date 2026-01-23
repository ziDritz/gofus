# scripts/core/entity_manager.gd
extends Node

## Manages the lifecycle and registry of all game entities

#region Signals

signal entity_registered(entity_id: String, entity: Node)
signal entity_unregistered(entity_id: String)
signal entity_spawned(entity_id: String, entity: Node)
signal entity_despawned(entity_id: String)

#endregion

#region State

var _entities: Dictionary = {}
var _entity_metadata: Dictionary = {}
var _next_id: int = 1000

#endregion

#region Lifecycle

func _ready() -> void:
	print("[EntityManager] Initialized")

#endregion

#region Entity Registration

func register_entity(entity: Node, entity_id: String = "") -> String:
	if entity_id.is_empty():
		entity_id = _generate_entity_id()
	
	if _entities.has(entity_id):
		push_error("[EntityManager] Entity ID already exists: %s" % entity_id)
		return ""
	
	_entities[entity_id] = entity
	
	_entity_metadata[entity_id] = {
		"type": _get_entity_type(entity),
		"spawned": false,
		"position": Vector2.ZERO,
		"map_id": ""
	}
	
	entity_registered.emit(entity_id, entity)
	print("[EntityManager] Registered entity: %s" % entity_id)
	
	return entity_id


func unregister_entity(entity_id: String) -> void:
	if not _entities.has(entity_id):
		push_warning("[EntityManager] Tried to unregister unknown entity: %s" % entity_id)
		return
	
	if _entity_metadata[entity_id]["spawned"]:
		despawn_entity(entity_id)
	
	_entities.erase(entity_id)
	_entity_metadata.erase(entity_id)
	
	entity_unregistered.emit(entity_id)
	print("[EntityManager] Unregistered entity: %s" % entity_id)

#endregion

#region Entity Spawning

func spawn_entity(entity_id: String, position: Vector2, map_id: String = "") -> bool:
	if not _entities.has(entity_id):
		push_error("[EntityManager] Cannot spawn unknown entity: %s" % entity_id)
		return false
	
	var entity = _entities[entity_id]
	
	_entity_metadata[entity_id]["spawned"] = true
	_entity_metadata[entity_id]["position"] = position
	_entity_metadata[entity_id]["map_id"] = map_id
	
	if entity is Node2D:
		entity.position = position
	
	if entity.has_method("on_spawned"):
		entity.on_spawned()
	
	entity_spawned.emit(entity_id, entity)
	print("[EntityManager] Spawned entity: %s at %v" % [entity_id, position])
	
	return true


func despawn_entity(entity_id: String) -> bool:
	if not _entities.has(entity_id):
		return false
	
	if not _entity_metadata[entity_id]["spawned"]:
		return false
	
	var entity = _entities[entity_id]
	
	_entity_metadata[entity_id]["spawned"] = false
	
	if entity.has_method("on_despawned"):
		entity.on_despawned()
	
	entity_despawned.emit(entity_id)
	print("[EntityManager] Despawned entity: %s" % entity_id)
	
	return true

#endregion

#region Query

func get_entity(entity_id: String) -> Node:
	return _entities.get(entity_id, null)


func has_entity(entity_id: String) -> bool:
	return _entities.has(entity_id)


func is_entity_spawned(entity_id: String) -> bool:
	if not _entity_metadata.has(entity_id):
		return false
	return _entity_metadata[entity_id]["spawned"]


func get_all_entities() -> Array:
	return _entities.values()


func get_entities_by_type(entity_type: String) -> Array:
	var result: Array = []
	
	for entity_id in _entities:
		if _entity_metadata[entity_id]["type"] == entity_type:
			result.append(_entities[entity_id])
	
	return result


func get_entities_in_range(position: Vector2, range: float, map_id: String = "") -> Array:
	var result: Array = []
	
	for entity_id in _entities:
		var metadata = _entity_metadata[entity_id]
		
		if not metadata["spawned"]:
			continue
		
		if not map_id.is_empty() and metadata["map_id"] != map_id:
			continue
		
		var distance = metadata["position"].distance_to(position)
		if distance <= range:
			result.append(_entities[entity_id])
	
	return result


func get_entities_on_map(map_id: String) -> Array:
	var result: Array = []
	
	for entity_id in _entities:
		var metadata = _entity_metadata[entity_id]
		
		if metadata["spawned"] and metadata["map_id"] == map_id:
			result.append(_entities[entity_id])
	
	return result

#endregion

#region Utility

func update_entity_position(entity_id: String, position: Vector2) -> void:
	if _entity_metadata.has(entity_id):
		_entity_metadata[entity_id]["position"] = position


func _generate_entity_id() -> String:
	var id = "entity_%d" % _next_id
	_next_id += 1
	return id


func _get_entity_type(entity: Node) -> String:
	if "entity_type" in entity:
		return entity.entity_type
	
	var script = entity.get_script()
	if script:
		return script.resource_path.get_file().get_basename()
	
	return "unknown"

#endregion

#region Debug

func print_registry() -> void:
	print("\n=== Entity Registry ===")
	print("Total entities: %d" % _entities.size())
	
	for entity_id in _entities:
		var metadata = _entity_metadata[entity_id]
		print("  %s: %s (spawned: %s)" % [
			entity_id,
			metadata["type"],
			metadata["spawned"]
		])

#endregion
