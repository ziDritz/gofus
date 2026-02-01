# MapResource.gd (merges Map.as and DofusMap.as)
# Data structure representing a complete map with all its cells and metadata

extends Resource
class_name MapResource

# =========================
# PROPERTIES
# =========================

## Map unique identifier
var map_id: int

## Map width in cells
var width: int

## Map height in cells
var height: int

## All cells in the map, indexed by cell_id
var cells: Array[CellResource]

var background_id: int

# =========================
# INITIALIZATION
# =========================

## Initialize map with all cells and metadata
## Flow: Raw parameters → initialized MapResource
func _init(p_map_id: int, p_width: int, p_height: int, p_cells: Array[CellResource]) -> void:
	map_id = p_map_id
	width = p_width
	height = p_height
	cells = p_cells
