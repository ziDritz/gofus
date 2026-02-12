# MapResource.gd (merges MapHandler.as and DofusMap.as)
# Data structure representing a complete map with all its cells and metadata

extends Resource
class_name MapResource

# =========================
# PROPERTIES
# =========================

## MapHandler unique identifier
var map_id: int

## MapHandler width in cells
var width: int

## MapHandler height in cells
var height: int

## All cells in the map, indexed by cell_id
var cells: Array[CellResource]


var background_id: int

# =========================
# INITIALIZATION
# =========================

## Initialize map with all cells and metadata
## Flow: Raw parameters → initialized MapResource
func _init(p_map_id: int, p_width: int, p_height: int, p_cells: Array[CellResource], p_background_id: int) -> void:
	map_id = p_map_id
	width = p_width
	height = p_height
	cells = p_cells
	background_id = p_background_id
