# battlefield.gd
extends Node
var loader_handler: LoaderHandler
var current_map: Map
var map_scene: PackedScene

## Initializes dependencies and event listening
func _ready() -> void:
	loader_handler = LoaderHandler.new()
	add_child(loader_handler)
	
	# Load the Map scene
	map_scene = load("res://graphics/battlefield/Map.tscn")
	if map_scene == null:
		push_error("Failed to load Map scene from res://graphics/battlefield/Map.tscn")


## Replaces old map with fresh rendering
func build_map(map_resource: MapResource) -> void:
	if current_map != null:
		current_map.queue_free()
		current_map = null

	current_map = map_scene.instantiate()
	current_map.initialize(map_resource, loader_handler)
	add_child(current_map)

