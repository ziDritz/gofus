# map_data.gd, equivalent of **Data Model** (`DofusMap`) holds map metadata and capabilities
# Holds map metadata (id, width, height, background) and array of all cells
class_name MapData
extends Resource

## Static data for a map

#region Core

var map_id: String = ""
var map_name: String = ""
var zone_id: String = ""

#endregion

#region Scene

var scene_path: String = ""

#endregion

#region Grid

var grid_width: int = 15
var grid_height: int = 17

#endregion

#region Connections

var connections: Array[Dictionary] = []

#endregion

#region Spawn Points

var spawn_points: Dictionary = {}

#endregion

#region Monster Spawns

var monster_spawns: Array[Dictionary] = []

#endregion

#region Serialization

func from_dict(data: Dictionary) -> void:
	map_id = data.get("map_id", "")
	map_name = data.get("map_name", "")
	zone_id = data.get("zone_id", "")
	
	scene_path = data.get("scene_path", "")
	
	grid_width = data.get("grid_width", 15)
	grid_height = data.get("grid_height", 17)
	
	connections = data.get("connections", [])
	
	var spawn_data = data.get("spawn_points", {})
	for spawn_name in spawn_data:
		var pos = spawn_data[spawn_name]
		spawn_points[spawn_name] = Vector2i(pos.x, pos.y)
	
	monster_spawns = data.get("monster_spawns", [])

#endregion
