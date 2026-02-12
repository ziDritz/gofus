# CellResource.gd
# Data structure representing a single cell's properties and state

extends Resource
class_name CellResource

# =========================
# PROPERTIES
# =========================

## Cell unique identifier
var cell_id: int

## Cell x position in grid
var grid_x: int

## Cell y position in grid
var grid_y: int

## Whether the cell can be walked on
var walkable: bool

## Active status
var active: bool

## Line of sight
var line_of_sight: bool

## Ground level (elevation)
var ground_level: int

## Movement value
var movement: int

## Ground slope
var ground_slope: int

## Object layer 2 number
var layer_object2_num: int

## Object layer 2 interactive status
var layer_object2_interactive: bool

## Server-side object logic
var object: int

## Ground layer rendering number
var layer_ground_num: int

## Ground layer rotation
var layer_ground_rot: int

## Ground layer flip
var layer_ground_flip: bool

## Object layer 1 (static decorations) number
var layer_object1_num: int

## Object layer 1 rotation
var layer_object1_rot: int

## Object layer 1 flip
var layer_object1_flip: bool

## Object layer 2 flip
var layer_object2_flip: bool

## External object layer (initially empty)
var layer_object_external: String

## External object layer interactive status
var layer_object_external_interactive: bool

## Permanent level offset (used in rendering calculations)
var permanent_level: int

## Is cell targetable for combat?
var is_targetable: bool

## Raw cell data string
var raw_data: String


## Initialize cell with all properties
## Flow: Raw cell data → initialized CellResource
func _init(
	p_cell_id: int,
	p_walkable: bool,
	p_active: bool = false,
	p_line_of_sight: bool = false,
	p_ground_level: int = 0,
	p_movement: int = 0,
	p_ground_slope: int = 0,
	p_layer_object2_num: int = 0,
	p_layer_object2_interactive: bool = false,
	p_object: int = -1,
	p_layer_ground_num: int = 0,
	p_layer_ground_rot: int = 0,
	p_layer_ground_flip: bool = false,
	p_layer_object1_num: int = 0,
	p_layer_object1_rot: int = 0,
	p_layer_object1_flip: bool = false,
	p_layer_object2_flip: bool = false,
	p_layer_object_external: String = "",
	p_layer_object_external_interactive: bool = false,
	p_permanent_level: int = 0,
	p_is_targetable: bool = false,
	p_raw_data: String = ""
) -> void:
	cell_id = p_cell_id
	walkable = p_walkable
	active = p_active
	line_of_sight = p_line_of_sight
	ground_level = p_ground_level
	movement = p_movement
	ground_slope = p_ground_slope
	layer_object2_num = p_layer_object2_num
	layer_object2_interactive = p_layer_object2_interactive
	object = p_object
	layer_ground_num = p_layer_ground_num
	layer_ground_rot = p_layer_ground_rot
	layer_ground_flip = p_layer_ground_flip
	layer_object1_num = p_layer_object1_num
	layer_object1_rot = p_layer_object1_rot
	layer_object1_flip = p_layer_object1_flip
	layer_object2_flip = p_layer_object2_flip
	layer_object_external = p_layer_object_external
	layer_object_external_interactive = p_layer_object_external_interactive
	permanent_level = p_permanent_level
	is_targetable = p_is_targetable
	raw_data = p_raw_data
