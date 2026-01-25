# Cell.gd
# Resource class representing a single map cell
# Contains all parsed properties from mapData
# Data structure representing a single cell's properties and state

class_name Cell
extends Resource

# Cell identification
var num: int = 0
var raw_data: String = ""

# Server-side gameplay properties
var active: bool = false
var line_of_sight: bool = false
var ground_level: int = 0
var movement: int = 0
var walkable: bool = false
var ground_slope: int = 0
var layer_object2_interactive: bool = false
var object: int = -1

# Client-side rendering properties - Ground layer
var layer_ground_num: int = 0
var layer_ground_rot: int = 0
var layer_ground_flip: bool = false

# Client-side rendering properties - Object layer 1
var layer_object1_num: int = 0
var layer_object1_rot: int = 0
var layer_object1_flip: bool = false

# Client-side rendering properties - Object layer 2
var layer_object2_num: int = 0
var layer_object2_flip: bool = false

# Additional properties
var layer_object_external: String = ""
var layer_object_external_interactive: bool = false
var permanent_level: int = 0
var is_targetable: bool = false


## Initialize cell from parsed dictionary
func from_dict(data: Dictionary) -> void:
	num = data.get("num", 0)
	raw_data = data.get("raw_data", "")
	
	# Server-side properties
	active = data.get("active", false)
	line_of_sight = data.get("line_of_sight", false)
	ground_level = data.get("ground_level", 0)
	movement = data.get("movement", 0)
	walkable = data.get("walkable", false)
	ground_slope = data.get("ground_slope", 0)
	layer_object2_interactive = data.get("layer_object2_interactive", false)
	object = data.get("object", -1)
	
	# Client-side rendering properties
	layer_ground_num = data.get("layer_ground_num", 0)
	layer_ground_rot = data.get("layer_ground_rot", 0)
	layer_ground_flip = data.get("layer_ground_flip", false)
	
	layer_object1_num = data.get("layer_object1_num", 0)
	layer_object1_rot = data.get("layer_object1_rot", 0)
	layer_object1_flip = data.get("layer_object1_flip", false)
	
	layer_object2_num = data.get("layer_object2_num", 0)
	layer_object2_flip = data.get("layer_object2_flip", false)
	
	# Additional
	layer_object_external = data.get("layer_object_external", "")
	layer_object_external_interactive = data.get("layer_object_external_interactive", false)
	permanent_level = data.get("permanent_level", 0)
	is_targetable = data.get("is_targetable", false)


## Check if cell is walkable
func is_walkable() -> bool:
	return active and walkable


## Get effective height including slope
func get_effective_height() -> int:
	return ground_level + ground_slope
