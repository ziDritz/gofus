# battlefield.gd
extends Node
var loader_handler: LoaderHandler
var current_map: Map
var map_scene: PackedScene

# =========================
# CONSTANTS
# =========================
const CELL_WIDTH: int = 106
const CELL_HALF_WIDTH: float = 53
const CELL_HEIGHT: int = 54  # Half-height for isometric
const CELL_HALF_HEIGHT: float = 27  # Half-height for isometric
const LEVEL_HEIGHT: int = 40  # Vertical offset per elevation level
const G_BOUNDS_JSON_PATH: String = "assets/graphics/gfx/grounds/g_bounds_x2.json"
const O_BOUNDS_JSON_PATH: String = "assets/graphics/gfx/objects/o_bounds_x2.json"


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
	add_child(current_map) # add_child allow to call _ready
	current_map.initialize(map_resource, loader_handler)
