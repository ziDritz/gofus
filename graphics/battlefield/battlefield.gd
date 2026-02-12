# battlefield.gd
extends Node
var loader_handler: LoaderHandler
var map_handler: MapHandler

const MAP_HANDLER_SCENE: PackedScene = preload("uid://4cltpjumsgaf")

# =========================
# CONSTANTS
# =========================
const CELL_WIDTH: int = 106
const CELL_HALF_WIDTH: float = 53
const CELL_HEIGHT: int = 54  # Half-height for isometric
const CELL_HALF_HEIGHT: float = 27  # Half-height for isometric
const LEVEL_HEIGHT: int = 40  # Vertical offset per elevation level
const G_METADATAS_JSON_PATH: String = "assets/graphics/gfx/grounds/ground_metadatas.json"
const O_BOUNDS_JSON_PATH: String = "assets/graphics/gfx/objects/o_bounds_x2.json"


## Initializes dependencies and event listening
func _ready() -> void:

	loader_handler = LoaderHandler.new()
	add_child(loader_handler)

	map_handler = MAP_HANDLER_SCENE.instantiate()
	add_child(map_handler) # add_child allow to call _ready
	map_handler.initialize(loader_handler)


func build_map(map_resource: MapResource) -> void:
	map_handler.build_map(map_resource)


func display_cell_ids() -> void:
	map_handler.display_cell_ids()
